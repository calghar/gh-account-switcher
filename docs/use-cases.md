# Use Cases

## Freelancers & Consultants

```bash
gh-switch add client-a contact@client-a.com "Your Name" CLIENT_A_GPG
gh-switch add client-b contact@client-b.com "Your Name" CLIENT_B_GPG

gh-switch auto ~/clients/client-a client-a
gh-switch auto ~/clients/client-b client-b
```

Commits automatically signed with correct identity per project.

## Work/Personal Separation

```bash
gh-switch add work jane@company.com "Jane Doe" WORK_GPG
gh-switch add personal jane@example.com "Jane Smith" PERSONAL_GPG

gh-switch auto ~/work work
gh-switch auto ~/personal personal
gh-switch auto ~/opensource personal
```

## Development Teams

Share standardized profiles:

```bash
# Team lead
gh-switch export > team-profiles.json

# Team members
gh-switch import team-profiles.json
gh-switch auto ~/projects/client-a client-a-profile
```

## Multiple Company Roles

```bash
gh-switch add work jane@company.com "Jane Doe"
gh-switch add-email work jane.contractor@company.com
gh-switch add-email work j.doe@consulting.com

# Switch between roles
gh-switch switch work jane.contractor@company.com
```

## Open Source Contributors

```bash
gh-switch add personal dev@example.com "Your Name"
gh-switch add work-oss dev@company.com "Your Name (Company)"

gh-switch auto ~/oss personal
gh-switch auto ~/work-oss work-oss
```

## Educational Institutions

```bash
gh-switch add student student.id@university.edu "Student Name"
gh-switch add research prof@university.edu "Dr. Name" RESEARCH_GPG

gh-switch auto ~/courses student
gh-switch auto ~/research research
```

## Compliance Requirements

Organizations requiring GPG signing:

```bash
gh-switch add company email@corp.com "Name" COMPANY_GPG_KEY
gh-switch auto ~/corp-repos company
```

All commits automatically signed, audit trail maintained.
