# Auto Branch Sync
This powershell script auto sync two branches. Useful to sync multi-Main/multi-release branches automatically.

# Example scenarios
When working with multi-release branching model where there is one release branch per version of the product(for example release-1.0 for version 1.0, release-2.0 for version 2.0, and so on). This is often done when it's a necessasity to maintain multiple version of the product and customers are using different versions. 

In such scenario, it's usually a manual task to sync between branches. For example, there are four versions of the products being maintained simutanously, release-1.0 for version 1.0, release-1.15 for version 1.15, release-2.0 for version 2.0 and release-3.0 for version 3.0

And then there is a main branch which is usually in sync with the higest version, release-3.0 in this scenario.

When a bug is found, we determine what was the oldest release of the system that was impacted. Developers then checkout the appropriate branch for that bug (or hotfix branch), make the fix, deploy it to a QA environment, verify the behavior, and then merge it forward to as many release branches as there are between that and main.

This is a painful task. 

# Script

This powershell script takes the following parameters, RepositoryUrl, SourceBranch, TargetBranch, gitlab token for AutoSyncUser and gitlab token for AutoSyncApprover. 

It can:
- Clone the repo using the AutoSyncUser token
- Checkout the SourceBranch
- Checkout a new branch from SourceBranch something like "sync/release-1-15-to-release-2-0" in case of release-1.15 being the source branch and release-2.0 being the target branch
- It then rebases the sync branch onto the TargetBranch
- Create a merge request with title something like "sync(release-1.15 to release-2.0): Sync release-1.15 to release-2.0". The target branch for the merge request should be TargetBranch. Keep the full change history. 
- Happy path: If there are no merge conflicts, AutoSyncApprover can approve the merge request and then AutoSyncUser can complete the merge request.
- Unhappy path: If there are merge conflcits, error with details of the conflicts and request user to resolve conflict manually.

When in unhappy path, there are two options for the user. One is to manually resolve conflicts and merge the merge request. Secondly, used can choose to rerun the script again.