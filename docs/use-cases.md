# Use Cases

## Development Teams

### Consistent Setup Across Team Members

- **Standardized profiles** - Share profile configurations via export/import
- **Directory-based rules** - Ensure everyone uses correct profiles per project
- **Automated switching** - Reduce human error with automatic profile detection

```bash
# Team lead exports standard profiles
gh-switch export > team-profiles.json

# Team members import and use
gh-switch import team-profiles.json
gh-switch auto ~/projects/client-a client-a-profile
gh-switch auto ~/projects/client-b client-b-profile
```

### Client Separation

- **Different profiles per client** with separate SSH keys and signing
- **Compliance requirements** met with proper identity separation
- **Billing tracking** made easier with distinct commit authors

### Signing Requirements

- **GPG signing per client** with different keys
- **Compliance auditing** with proper commit attribution
- **Security policies** enforced automatically

## Individual Developers

### Work/Personal Separation

Perfect for developers who contribute to both work and personal projects.

```bash
# Set up work and personal profiles
gh-switch add work jane.doe@company.com "Jane Doe" WORK_GPG_KEY
gh-switch add personal jane@example.com "Jane Smith" PERSONAL_GPG_KEY

# Set up automatic switching
gh-switch auto ~/work work
gh-switch auto ~/personal personal
gh-switch auto ~/opensource personal
```

### Multiple Email Contexts

For developers with different roles:

```bash
# Add multiple emails to work profile
gh-switch add work jane.doe@company.com "Jane Doe" GPG_KEY
gh-switch add-email work jane.contractor@company.com
gh-switch add-email work j.doe@consulting.com

# Switch between contexts easily
gh-switch switch work jane.contractor@company.com  # Contractor work
gh-switch switch work jane.doe@company.com         # Employee work
```

### Different SSH Keys Per Account

Manage multiple GitHub accounts with separate SSH keys:

```bash
# SSH key naming convention: ~/.ssh/id_{profile}
# Create keys: ssh-keygen -t ed25519 -f ~/.ssh/id_work
# Create keys: ssh-keygen -t ed25519 -f ~/.ssh/id_personal

# Switch and auto-add SSH keys
gh-switch --auto-ssh switch work     # Loads ~/.ssh/id_work
gh-switch --auto-ssh switch personal # Loads ~/.ssh/id_personal
```

## Organizations

### Standardized Configurations

Large organizations can standardize developer setups:

```bash
# Create organization profile template
{
  "company": {
    "emails": ["employee@company.com"],
    "primary_email": "employee@company.com",
    "name": "Employee Name",
    "gpg_key": "COMPANY_GPG_KEY"
  }
}

# Distribute to all developers
gh-switch import company-template.json
```

### Audit Trails

- **Commit tracking** with proper author information
- **Security compliance** with mandatory GPG signing
- **Department separation** with different profiles per team

### Security Compliance

- **Mandatory signing** with organization GPG keys
- **SSH key management** with automatic keychain integration
- **Identity verification** with consistent email/name combinations

## Freelancers and Consultants

### Client Isolation

```bash
# Set up separate profiles for each client
gh-switch add client-a contact@client-a.com "Consultant Name" CLIENT_A_GPG
gh-switch add client-b contact@client-b.com "Consultant Name" CLIENT_B_GPG

# Organize projects by client
gh-switch auto ~/clients/client-a client-a
gh-switch auto ~/clients/client-b client-b
```

### Professional Branding

- **Consistent identity** per client with appropriate email/name
- **Professional signatures** with client-specific GPG keys
- **Separate SSH access** to different client repositories

## Open Source Contributors

### Multiple Project Identities

```bash
# Personal identity for own projects
gh-switch add personal dev@example.com "Your Name"

# Company identity for work-sponsored contributions
gh-switch add work-oss dev@company.com "Your Name (Company)"

# Anonymous identity for sensitive contributions
gh-switch add anonymous noreply@github.com "Contributor"
```

### Foundation/Organization Contributions

```bash
# Set up foundation-specific identity
gh-switch add apache dev@apache.org "Your Name" APACHE_GPG_KEY
gh-switch auto ~/projects/apache-* apache
```

## Educational Institutions

### Student/Faculty Separation

```bash
# Student identity
gh-switch add student student.id@university.edu "Student Name"

# Faculty/research identity
gh-switch add faculty faculty@university.edu "Dr. Faculty Name" RESEARCH_GPG

# Personal projects
gh-switch add personal personal@email.com "Real Name"
```

### Course Management

```bash
# Set up per-course identities
gh-switch add cs101 student@university.edu "Student (CS101)"
gh-switch add cs201 student@university.edu "Student (CS201)"

# Auto-switch based on project directories
gh-switch auto ~/courses/cs101 cs101
gh-switch auto ~/courses/cs201 cs201
```
