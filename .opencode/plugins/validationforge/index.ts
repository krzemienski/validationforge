import { type Plugin, tool } from "@opencode-ai/plugin"
import { z } from "zod"
import {
  isBlockedTestFile,
  detectMockPatterns,
  isBuildSuccess,
  isCompletionClaim,
  isValidationCommand,
} from "./patterns"
import { existsSync, readdirSync, statSync } from "fs"
import { join, resolve as resolvePath, sep as pathSep } from "path"

const EVIDENCE_DIR = "e2e-evidence"

const plugin: Plugin = async ({ directory, $ }) => {
  return {
    // ────────────────────────────────────────────────────────────
    // Custom tools — registered via the `tool()` helper with zod
    // schemas (per the OpenCode plugin API).
    // ────────────────────────────────────────────────────────────
    tool: {
      vf_validate: tool({
        description:
          "Run ValidationForge validation pipeline. Detects platform, maps journeys, captures evidence, writes verdicts.",
        args: z.object({
          platform: z
            .string()
            .optional()
            .describe("Force platform: ios, web, api, cli, fullstack"),
          scope: z
            .string()
            .optional()
            .describe("Limit validation to a specific directory or feature"),
        }),
        async execute(args) {
          const platformFlag = args.platform ? `--platform ${args.platform}` : ""
          const scopeFlag = args.scope ? `--scope ${args.scope}` : ""
          return `Invoke /validate ${platformFlag} ${scopeFlag}`.trim()
        },
      }),
      vf_check_evidence: tool({
        description:
          "Check if validation evidence exists and report its status.",
        args: z.object({
          journey: z
            .string()
            .optional()
            .describe("Specific journey slug to check"),
        }),
        async execute(args) {
          const evidencePath = join(directory, EVIDENCE_DIR)
          if (!existsSync(evidencePath)) {
            return "No e2e-evidence/ directory found. Run /validate first."
          }
          const entries = readdirSync(evidencePath)
          if (entries.length === 0) {
            return "e2e-evidence/ exists but is empty. No evidence captured yet."
          }
          if (args.journey) {
            // Guard against path traversal: reject any `args.journey` that
            // escapes the evidence directory. (review finding L3)
            const journeyPath = resolvePath(evidencePath, args.journey)
            const evidenceRoot = resolvePath(evidencePath) + pathSep
            if (!journeyPath.startsWith(evidenceRoot)) {
              return `Invalid journey slug "${args.journey}" — path traversal rejected.`
            }
            if (!existsSync(journeyPath)) {
              return `No evidence for journey "${args.journey}". Available: ${entries.join(", ")}`
            }
            const files = readdirSync(journeyPath)
            return `Journey "${args.journey}": ${files.length} evidence files.\n${files.join("\n")}`
          }
          return `Evidence directories: ${entries.join(", ")}`
        },
      }),
    },

    // ────────────────────────────────────────────────────────────
    // Pre-execution gate: block test/mock file creation BEFORE the
    // tool runs. Using `tool.execute.before` (documented) instead of
    // the non-existent `permission.ask` event.
    // ────────────────────────────────────────────────────────────
    "tool.execute.before": async (input: any, output: any) => {
      const toolName = (input?.tool || "").toLowerCase()
      if (!["write", "edit", "multiedit"].includes(toolName)) return

      const filePath =
        output?.args?.file_path ||
        output?.args?.filePath ||
        input?.args?.file_path ||
        input?.args?.filePath ||
        ""

      const reason = isBlockedTestFile(filePath)
      if (reason) {
        throw new Error(
          `ValidationForge: ${reason}. If the real system doesn't work, fix the real system.`
        )
      }
    },

    // ────────────────────────────────────────────────────────────
    // Post-execution: advisory reminders on bash/write output.
    // ────────────────────────────────────────────────────────────
    "tool.execute.after": async (input: any, output: any) => {
      const toolName = (input?.tool || "").toLowerCase()
      const args = input?.args || {}

      // After Bash: surface build-success ≠ validation and completion-without-evidence.
      if (toolName === "bash") {
        const result = output?.output || ""
        if (isBuildSuccess(result)) {
          output.metadata = {
            ...output.metadata,
            vf_reminder:
              "Build succeeded, but compilation is NOT validation. Run /validate to verify through real user interfaces.",
          }
        }
        if (isCompletionClaim(result)) {
          const evidencePath = join(directory, EVIDENCE_DIR)
          const hasEvidence =
            existsSync(evidencePath) && readdirSync(evidencePath).length > 0
          if (!hasEvidence) {
            output.metadata = {
              ...output.metadata,
              vf_warning:
                "Completion claimed but no evidence in e2e-evidence/. Run /validate first.",
            }
          }
        }
        const command = args.command || ""
        if (isValidationCommand(command)) {
          output.metadata = {
            ...output.metadata,
            vf_note:
              "Validation activity detected. Remember to capture evidence to e2e-evidence/.",
          }
        }
      }

      // After Write/Edit: mock detection + evidence-quality check.
      if (["write", "edit", "multiedit"].includes(toolName)) {
        const content = args.content || args.new_string || ""
        if (content && detectMockPatterns(content)) {
          output.metadata = {
            ...output.metadata,
            vf_warning:
              "Mock/test pattern detected in written code. ValidationForge Iron Rule: never create mocks or test harnesses.",
          }
        }
        const filePath = args.file_path || args.path || ""
        if (filePath.includes("e2e-evidence")) {
          // 0-byte files are invalid evidence. Prefer content-size check
          // over stat so we catch intended empties, not transient ones.
          const isEmpty = !content || content.length === 0
          if (isEmpty) {
            output.metadata = {
              ...output.metadata,
              vf_warning:
                "Empty evidence file detected. 0-byte files are INVALID evidence.",
            }
          } else {
            // Belt-and-suspenders: if the file landed on disk, verify size.
            try {
              const stats = statSync(filePath)
              if (stats.size === 0) {
                output.metadata = {
                  ...output.metadata,
                  vf_warning:
                    "Empty evidence file on disk. 0-byte files are INVALID evidence.",
                }
              }
            } catch {
              // File not written yet or unreadable; content-size check above is authoritative.
            }
          }
        }
      }
    },

    // ────────────────────────────────────────────────────────────
    // Shell env: inject VF_* variables so bash tools can see config.
    // ────────────────────────────────────────────────────────────
    "shell.env": async () => {
      return {
        env: {
          VF_EVIDENCE_DIR: EVIDENCE_DIR,
          VF_VERSION: "1.0.0",
          VF_ENFORCEMENT: "standard",
        },
      }
    },

    // NOTE: The empty `event` handler that previously lived here has
    // been removed — it was not a documented OpenCode hook and the
    // body was dead code. Re-add via a concrete documented event
    // (`session.idle`, `file.edited`, …) if/when needed.
  }
}

export default plugin
