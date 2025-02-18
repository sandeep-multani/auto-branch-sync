param (
    [string]$RepositoryUrl,
    [string]$SourceBranch,
    [string]$TargetBranch,
    [string]$AutoSyncUserToken,
    [string]$AutoSyncApproverToken
)

# Function to execute git commands
function Execute-GitCommand {
    param (
        [string]$Command
    )
    $output = & git $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Git command failed: $Command"
        exit $LASTEXITCODE
    }
    return $output
}

# Clone the repository
Execute-GitCommand "clone https://$AutoSyncUserToken@$RepositoryUrl repo"
Set-Location -Path "./repo"

# Checkout the source branch
Execute-GitCommand "checkout $SourceBranch"

# Create a new sync branch
$cleanSourceBranch = $SourceBranch -replace '[^a-zA-Z0-9]', '-'
$cleanTargetBranch = $TargetBranch -replace '[^a-zA-Z0-9]', '-'
$syncBranchName = "sync/$cleanSourceBranch-to-$cleanTargetBranch"
Execute-GitCommand "checkout -b $syncBranchName"

# Rebase the sync branch onto the target branch
Execute-GitCommand "rebase origin/$TargetBranch"

# Push the sync branch to the remote repository
Execute-GitCommand "push origin $syncBranchName"

# Create a merge request
$mergeRequestTitle = "sync($SourceBranch to $TargetBranch): Sync $SourceBranch to $TargetBranch"
$mergeRequestDescription = "This merge request syncs $SourceBranch to $TargetBranch."
$mergeRequestData = @{
    source_branch = $syncBranchName
    target_branch = $TargetBranch
    title         = $mergeRequestTitle
    description   = $mergeRequestDescription
}

$mergeRequestJson = $mergeRequestData | ConvertTo-Json -Compress
$mergeRequestUrl = "https://gitlab.com/api/v4/projects/$(($RepositoryUrl -replace 'https://|.git', '') -replace '/', '%2F')/merge_requests"

Invoke-RestMethod -Method Post -Uri $mergeRequestUrl -Headers @{ "PRIVATE-TOKEN" = $AutoSyncUserToken } -Body $mergeRequestJson -ContentType "application/json"

Write-Output "Merge request created successfully."

# Approve the merge request
$mergeRequestId = (Invoke-RestMethod -Method Get -Uri $mergeRequestUrl -Headers @{ "PRIVATE-TOKEN" = $AutoSyncUserToken }).id
$approveUrl = "$mergeRequestUrl/$mergeRequestId/approve"

Invoke-RestMethod -Method Post -Uri $approveUrl -Headers @{ "PRIVATE-TOKEN" = $AutoSyncApproverToken }

Write-Output "Merge request approved successfully."

# Merge the merge request
$mergeUrl = "$mergeRequestUrl/$mergeRequestId/merge"

Invoke-RestMethod -Method Put -Uri $mergeUrl -Headers @{ "PRIVATE-TOKEN" = $AutoSyncUserToken }

Write-Output "Merge request merged successfully."