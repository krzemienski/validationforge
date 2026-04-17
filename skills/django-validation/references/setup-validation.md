# Setup Validation (Steps 1–3)

Supports **Step 1 (Install Dependencies)**, **Step 2 (Django System Check)**, and
**Step 3 (Migration Status)**. Teaches the pattern: run each setup command with
`tee` to capture output as evidence, then grep the output file for a known-good
marker before proceeding.

## Step 1: Install Dependencies

```bash
# Install from requirements file
pip install -r requirements.txt 2>&1 | tee e2e-evidence/django-pip-install.txt

# Or with pip-tools
pip install pip-tools && pip-sync requirements.txt 2>&1 | tee e2e-evidence/django-pip-install.txt
```

Check result:
```bash
if grep -qE "Successfully installed|already satisfied" e2e-evidence/django-pip-install.txt; then
  echo "PASS: Dependencies installed"
else
  echo "FAIL: pip install failed — check requirements.txt and Python version"
  cat e2e-evidence/django-pip-install.txt
  exit 1
fi
```

## Step 2: Django System Check

Run Django's built-in system check to catch configuration errors before starting:

```bash
python manage.py check 2>&1 | tee e2e-evidence/django-check.txt
```

Check result:
```bash
if grep -q "System check identified no issues" e2e-evidence/django-check.txt; then
  echo "PASS: Django system check clean"
else
  echo "FAIL: Django system check found issues"
  cat e2e-evidence/django-check.txt
  exit 1
fi
```

For deployment-readiness check:
```bash
python manage.py check --deploy 2>&1 | tee e2e-evidence/django-check-deploy.txt
```

## Step 3: Migration Status

Verify all database migrations are applied:

```bash
python manage.py showmigrations 2>&1 | tee e2e-evidence/django-migrations.txt
```

Check for unapplied migrations:
```bash
if grep -q "[ ]" e2e-evidence/django-migrations.txt; then
  echo "FAIL: Unapplied migrations found — run 'python manage.py migrate'"
  grep "[ ]" e2e-evidence/django-migrations.txt
else
  echo "PASS: All migrations applied"
fi
```

Apply any outstanding migrations:
```bash
python manage.py migrate 2>&1 | tee e2e-evidence/django-migrate.txt
```

## Virtualenv reminder

If using a virtual environment, activate it first:
```bash
# Create virtualenv
python -m venv venv

# Activate (Linux/macOS)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Verify activation
which python
```
