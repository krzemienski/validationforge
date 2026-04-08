import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin/tool"
import {
  isBlockedTestFile,
  detectMockPatterns,
  isBuildSuccess,
  isCompletionClaim,
  isValidationCommand,
} from "./patterns"
import { existsSync, readdirSync } from "fs"
import { join } from "path"

const EVIDENCE_DIR = "e2e-evidence"

const plugin: Plugin = async ({ directory, $ }) => {
  return {
    // Custom tool: run validation directly from agent context
    tool: {
      vf_validate: tool({
        description:
          "Run ValidationForge validation pipeline. Detects platform, maps journeys, captures evidence, writes verdicts.",
        args: {
          platform: tool.schema
            .string()
            .optional()
            .describe("Force platform: ios, web, api, cli, fullstack"),
          scope: tool.schema
            .string()
            .optional()
            .describe("Limit validation to a specific directory or feature"),
        },
        async execute(args, context) {
          const platformFlag = args.platform ? `--platform ${args.platform}` : ""
          const scopeFlag = args.scope ? `--scope ${args.scope}` : ""
          return `Invoke /validate ${platformFlag} ${scopeFlag}`.trim()
        },
      }),
      vf_check_evidence: tool({
        description:
          "Check if validation evidence exists and report its status.",
        args: {
          journey: tool.schema
            .string()
            .optional()
            .describe("Specific journey slug to check"),
        },
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
            const journeyPath = join(evidencePath, args.journey)
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

    // Block test/mock file creation
    "permission.ask": async (input, output) => {
      const tool = (input as any).tool || ""
      if (!["write", "edit", "multiedit"].includes(tool.toLowerCase())) return

      const filePath = (input as any).args?.file_path || (input as any).args?.filePath || ""
      const reason = isBlockedTestFile(filePath)
      if (reason) {
        output.status = "deny"
      }
    },

    // Intercept tool execution for validation enforcement
    "tool.execute.after": async (input, output) => {
      const toolName = (input as any).tool || ""
      const args = (input as any).args || {}

      // After Bash: check for build-success-is-not-validation
      if (toolName.toLowerCase() === "bash") {
        const result = (output as any).output || ""
        if (isBuildSuccess(result)) {
          ;(output as any).metadata = {
            ...(output as any).metadata,
            vf_reminder:
              "Build succeeded, but compilation is NOT validation. Run /validate to verify through real user interfaces.",
          }
        }
        // Check for completion claims without evidence
        if (isCompletionClaim(result)) {
          const evidencePath = join(directory, EVIDENCE_DIR)
          const hasEvidence =
            existsSync(evidencePath) && readdirSync(evidencePath).length > 0
          if (!hasEvidence) {
            ;(output as any).metadata = {
              ...(output as any).metadata,
              vf_warning:
                "Completion claimed but no evidence in e2e-evidence/. Run /validate first.",
            }
          }
        }
        // Track validation commands
        const command = args.command || ""
        if (isValidationCommand(command)) {
          ;(output as any).metadata = {
            ...(output as any).metadata,
            vf_note:
              "Validation activity detected. Remember to capture evidence to e2e-evidence/.",
          }
        }
      }

      // After Write/Edit: detect mock patterns and check evidence quality
      if (["write", "edit", "multiedit"].includes(toolName.toLowerCase())) {
        const content = args.content || args.new_string || ""
        if (content && detectMockPatterns(content)) {
          ;(output as any).metadata = {
            ...(output as any).metadata,
            vf_warning:
              "Mock/test pattern detected in written code. ValidationForge Iron Rule: never create mocks or test harnesses.",
          }
        }
        // Evidence quality check
        const filePath = args.file_path || args.path || ""
        if (filePath.includes("e2e-evidence") && (!content || content.length === 0)) {
          ;(output as any).metadata = {
            ...(output as any).metadata,
            vf_warning:
              "Empty evidence file detected. 0-byte files are INVALID evidence.",
          }
        }
      }
    },

    // Inject VF environment variables into shell
    "shell.env": async () => {
      return {
        env: {
          VF_EVIDENCE_DIR: EVIDENCE_DIR,
          VF_VERSION: "1.0.0",
          VF_ENFORCEMENT: "standard",
        },
      }
    },

    // Subscribe to events for tracking
    event: async ({ event }) => {
      // Future: track session.idle for evidence capture reminders
      // Future: track file.edited for automatic evidence validation
    },
  }
}

export default plugin
