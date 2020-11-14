#
# ProjectMaker.ps1
#

$cwd = $PSScriptRoot
Set-Location -Path $cwd

$template1 = ".\Template.vcxproj"
$context1 = Get-Content -Path $template1 -Encoding UTF8

$template2 = ".\Template.vcxproj.filters"
$context2 = Get-Content -Path $template2 -Encoding UTF8

$template3 = ".\packages.config"

$result = ".\result.md"
$url = "https://github.com/opencv/opencv/blob/master/samples/cpp/"

$excludes = @("asift", "epipolar_lines", "essential_mat_reconstr", "stitching_detailed")

$target = "C:\Users\User01\source\Archives\opencv-master\samples\cpp"
$fileList = Get-ChildItem -Path $target -Filter "*.cpp" |
            Where-Object { $excludes -notcontains $_.BaseName }

# result�̍쐬
New-Item -ItemType File -Path $result | Out-Null
Add-Content "# OpenCV samples"     -Path $result -Encoding UTF8 | Out-Null
Add-Content ""                     -Path $result -Encoding UTF8 | Out-Null
Add-Content "## Information"       -Path $result -Encoding UTF8 | Out-Null
Add-Content ""                     -Path $result -Encoding UTF8 | Out-Null
Add-Content "|Title|FileName/URL|" -Path $result -Encoding UTF8 | Out-Null
Add-Content "|-----|------------|" -Path $result -Encoding UTF8 | Out-Null

foreach ($file in $fileList) {
    if ($file.Attributes -eq "Directory") {
        # ignore
    } else {
        # �W�J��̃t�H���_��
        $destination = "..\" + $file.BaseName

        # �f�B���N�g���̍쐬
        New-Item -ItemType Directory -Path $destination | Out-Null

        # �\�[�X�t�@�C���̃R�s�[
        $source = $target + "\" + $file.Name
        Copy-Item -Path $source -Destination $destination
        
        # �p�b�P�[�W�ݒ�t�@�C���̃R�s�[
        Copy-Item -Path $template3 -Destination $destination

        # �t�@�C��1�̍쐬
        $newFile1 = $destination + "\" + $file.BaseName + ".vcxproj"
        New-Item -ItemType File -Path $newFile1 | Out-Null

        # �e���v���[�g1�̓��e��ύX
        foreach ($row in $context1) {
            if ($row.IndexOf("%GUID%") -gt 0) {
                $row = $row.Replace("%GUID%", (New-Guid).Guid)
            }

            if ($row.IndexOf("%TARGET_NAME%") -gt 0) {
                $row = $row.Replace("%TARGET_NAME%", $file.BaseName)
                Write-Output $file.BaseName
            }

            if ($row.IndexOf("%TARGET_FILE_NAME%") -gt 0) {
                $row = $row.Replace("%TARGET_FILE_NAME%", $file.Name)
            }

            Add-Content $row -Path $newFile1 -Encoding UTF8 | Out-Null
        }
        
        # �t�@�C��2�̍쐬
        $newFile2 = $destination + "\" + $file.BaseName + ".vcxproj.filters"
        New-Item -ItemType File -Path $newFile2 | Out-Null

        # �e���v���[�g2�̓��e
        foreach ($row in $context2) {
            if ($row.IndexOf("%TARGET_FILE_NAME%") -gt 0) {
                $row = $row.Replace("%TARGET_FILE_NAME%", $file.Name)
            }

            Add-Content $row -Path $newFile2 -Encoding UTF8 | Out-Null
        }

        # result.md�ɒǉ�
        $resultRow = "|" + $file.BaseName + "|[" + $file.Name + "](" + $url + $file.Name + ")|" 
        Add-Content $resultRow -Path $result -Encoding UTF8 | Out-Null
    }
}