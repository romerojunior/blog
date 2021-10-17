---
layout: post
title: "Structuring Ansible Projects"
author: "Romero Jr"
comments: true
---

Those experienced with Chef probably first heard about reusability, structuring and versioning when writing their very first cookbook, but as a newcomer to Ansible and facing AWX for the very first time, this seems to be one of the last explored topics, if not left completely unanswered (mostly due to Ansible's simplistic nature).

Even though Ansible provides engineers with a decent amount of information on roles and playbooks, it still leaves room for interpretation on how your code should be structured within an organization or a team. Without prior experience it may be a challenge to visualise the end product, specially in the long term. The question is: How can we organize our Ansible code in a intuitive and readable way, and improve reusability at the same time?

In order to answer the question, firstly, an understanding of what each component is concerned about and how they can be accessed need to be agreed upon. Below you will find guidelines based on how I've personally interpretated the problem.

# Access policy

- Roles are intrinsically public, therefore they must not hold any private information.

- Playbooks are threated as private, considering they may contain data that should not be publically accessed or shared across teams, for example: variables storing valuable information about a particular host.

# Separation of concerns

## Separation of concerns within roles

- Roles must not contain any unsolved dependencies, for example: If a specific package is required for a given role to function, this dependency needs to be dealt within the role itself.

- If a given value may change depending on external requirements, this value should be defined as a variable (allowing for a playbook to override it if and when needed).

- Each role is free to `set_facts` on any host. This is particularly useful as triggers for further steps within a playbook (but never another role, since ideally roles should never be aware or depend on a different role). I personally like to think about this as the way a role can communicate back to a playbook.

  - When set, a fact **must** be **defined** within all test cases. For example, if you need to set a fact such as `update_needed = true`, its value needs to default to something (either `true` or `false`). A host should never finish running a role without defining `update_needed`. A short example:

```yml
# Let's pretend for a minute we're writing a task within a role responsible for checking if any updates are need within a CentOS/RHEL host...

# start assuming no updates are needed (default behaviour):
- set_fact:
    update_needed: false

# check if updates are needed...
- name: check yum updates
  command: "yum check-update -q"
  register: yum_results

# ...if so, set fact to true:
- set_fact:
    update_needed: true
  when: yum_results.rc | int == 100
```

- Each role has the responsibility to deal with technicalities such as:

  - Handling different operational systems; and
  - Catching execution failures;

## Separation of concerns within playbooks

As technicalities are left for roles to deal with, in theory each playbook should be straight forward:

- Each playbook is aware of the details of the environment (represented within an inventory) in which it will be running against.

- A playbook can overwrite role default variables when needed (allowing each team to customize the execution of a whole without unnecessary code changes, as previously stated).

- A good playbook would ideally only control the flow in which roles are executed, managing triggers, for example:

```yml
# Assume you have a playbook responsible for patching hosts:

- hosts: all
  gather_facts: true
  become: yes
  roles:
    - role: check-updates

    - role: install-updates
      when:
        - update_needed | default(false)

    - role: reboot-host
      when:
        - reboot_required | default(false)

    # check-updates sets a fact called "update_needed"
    # install-updates is triggered if "update_needed" is true
    # install-updates sets a fact called "reboot_required"
    # reboot-host is triggered if "reboot_required" is true
```

- Again, if a given value may change depending on execution requirements, this value should be defined as a variable (allowing the engineer to change its execution behaviour without unnecessary code changes).

- Playbooks should import/install roles through the `requirements.yml` file, as documented [here](https://docs.ansible.com/ansible/latest/reference_appendices/galaxy.html#installing-roles), instead of having their code simply moved, pasted or cloned.

# Directory structure and Git

With the agreement above in mind, the last question to be answered is how to organize all the roles and playbooks directory structure.
The approach I personally opt for is rather simple, where each role or playbook is a repository of its own. For example:

```text
ansible/
│
├── playbooks/
│   ├── play_automated_patching/  <──┐
│   ├── play_baseline_config/     <──┼─ private repositories
│   └── play_setup_django/        <──┘
│
├── roles/
│   ├── role_install_nginx/       <──┐
│   ├── role_install_mariadb/     <──┤
│   ├── role_install_python/      <──┼─ public repositories
│   ├── role_install_updates/     <──┤
│   ├── role_reboot_host/         <──┤
│   └── role_check_updates/       <──┘
│
└── README.md

```

# Final considerations

No matter what rules, architecture or pattern you end up opting for, they must be shared and respected by all of those involved in maintaining the Ansible code base, I believe this is a fundamental key in improving reusability and quality.
