# OpenCV sample build by Visual Studio Community 2019

# これはなにか？

これはOpenCVプロジェクトにあるsampleフォルダに入っているCPPフォルダのサンプルを、Visual Studio Community 2019でビルドできるように、プロジェクトを自動生成したものです。ソリューションへの登録は手動になります。

# どうなっているのか？

OpenCVプロジェクトにあるC/C++用サンプルプログラムは、フォルダにある各ソースコードが独立して実行ファイルになれる（main()を各ファイルが持っている）ものです。CMakeでビルドした場合は個別に実行ファイルが作られるのかもしれませんが、Visual Studioでビルドする場合は、どうしてもプロジェクトファイルが必要になります。

ということで、できるだけオリジナルのソースコードを使用して、プロジェクトファイルはそれぞれのビルド用の環境を設定して、ビルドとデバッグ実行ができるように環境を構築しました。CPPフォルダのサンプルのうち、４つはまだ私の理解していないライブラリを使用していたため、今回は割愛させていただきました。

プロジェクトファイルの作成に当たり、テンプレートから各ソースコード用のプロジェクトを作るために、PowerShellでスクリプトを作りました。Workフォルダに
ProjectMaker.ps1として保管しています。

テンプレートとなる、vcxproj、vcxproj.filterは、Visual Studio Community 2019で作成したものを使っています。2015で比較してもバージョン情報の部分が違っているくらいでしたので、多分ですが、2015、2017でも作れると思います。

もし、作り直す場合は、以下のようにやってみてください。

1. cloneやZIPダウンロードして、環境を手元に作った場合、いったんWorkフォルダだけにしてしまいます。
1. テンプレートとして使用するファイルをお手元のVisual Studioで作ったファイルと比較して、変更すべきバージョン番号などを書き換えます。
1. OpenCVのサンプルソースコードもお手元に準備しておいてください。ダウンロード版でも問題ありません。多分ですが、改行コードがLFだけだと思いますが、Visual Studio的には問題ないようです。
1. $target = "C:\Users\User01\source\Archives\opencv-master\samples\cpp"のコードはお手元の環境に合わせてください。
1. PowerShellスクリプトを実行してください。多分、このリポジトリと同じようにできているはずです。
1. 最後に申し訳ありません。ソリューションへは手動で設定することになります。ここまでスクリプトでやるべきだと思うのですが、現時点で力尽きています。

```ps1
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

# resultの作成
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
        # 展開先のフォルダ名
        $destination = "..\" + $file.BaseName

        # ディレクトリの作成
        New-Item -ItemType Directory -Path $destination | Out-Null

        # ソースファイルのコピー
        $source = $target + "\" + $file.Name
        Copy-Item -Path $source -Destination $destination
        
        # パッケージ設定ファイルのコピー
        Copy-Item -Path $template3 -Destination $destination

        # ファイル1の作成
        $newFile1 = $destination + "\" + $file.BaseName + ".vcxproj"
        New-Item -ItemType File -Path $newFile1 | Out-Null

        # テンプレート1の内容を変更
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
        
        # ファイル2の作成
        $newFile2 = $destination + "\" + $file.BaseName + ".vcxproj.filters"
        New-Item -ItemType File -Path $newFile2 | Out-Null

        # テンプレート2の内容
        foreach ($row in $context2) {
            if ($row.IndexOf("%TARGET_FILE_NAME%") -gt 0) {
                $row = $row.Replace("%TARGET_FILE_NAME%", $file.Name)
            }

            Add-Content $row -Path $newFile2 -Encoding UTF8 | Out-Null
        }

        # result.mdに追加
        $resultRow = "|" + $file.BaseName + "|[" + $file.Name + "](" + $url + $file.Name + ")|" 
        Add-Content $resultRow -Path $result -Encoding UTF8 | Out-Null
    }
}
```

現時点のOpenCVの環境はNuGetを使用して、4.2.0が構築環境にダウンロードされるようにしています。最新のOpenCV環境ではないため、qrcode.cppは、#if 0 でdetectAndDecodeMulti()の部分をコメントアウトしています。

プロジェクトテンプレートに「_CRT_SECURE_NO_WARNINGS」の定義を仕込みました。一部のソースコードはこれがないと「警告」ではなく、「エラー」になってしまいます。ソースコードにできるだけ、手を加えずにいたかったのでこのような方法をとりましたが、サンプルからノウハウを取得する際は、安全面にも考慮してポーティングしてください。

また、不本意ではありますがRelase/Debugフォルダ配下にOpenCVのDLLを配置しました。本来であれば、「ビルド後のイベント」としてCOPYコマンドやXCOPYコマンドを使用してライブラリフォルダからコピーするのが筋ではあります。しかし、依存関係が全くないプロジェクトなので、コピー処理が重複してエラーになってしまいます。あれこれ悩むよりまずは動かしてみよう、という気持ちで現状そうしています。

# サンプルのそれぞれの説明はないのか？

申し訳ありません。まだ、Visual Studioで動かしてみたいな、なノリで作った程度なので個別の説明には至っていません。一番最初に動作確認としてお薦めなのは、「videocapture_basic」です。動かすにはカメラが必要です。私はHyvper-V環境でいつも開発しているのですが、「リモートデスクトップ接続」でつなげると、手元のUSB接続（のつもりのないハードウェアも）を使ってカメラを使うことができます。

サンプルファイルのありかは、以下のURLをご参照ください。

# OpenCV samples

## Information

|Title|FileName/URL|
|-----|------------|
|3calibration|[3calibration.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/3calibration.cpp)|
|application_trace|[application_trace.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/application_trace.cpp)|
|bgfg_segm|[bgfg_segm.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/bgfg_segm.cpp)|
|calibration|[calibration.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/calibration.cpp)|
|camshiftdemo|[camshiftdemo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/camshiftdemo.cpp)|
|cloning_demo|[cloning_demo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/cloning_demo.cpp)|
|cloning_gui|[cloning_gui.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/cloning_gui.cpp)|
|connected_components|[connected_components.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/connected_components.cpp)|
|contours2|[contours2.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/contours2.cpp)|
|convexhull|[convexhull.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/convexhull.cpp)|
|cout_mat|[cout_mat.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/cout_mat.cpp)|
|create_mask|[create_mask.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/create_mask.cpp)|
|dbt_face_detection|[dbt_face_detection.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/dbt_face_detection.cpp)|
|delaunay2|[delaunay2.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/delaunay2.cpp)|
|demhist|[demhist.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/demhist.cpp)|
|detect_blob|[detect_blob.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/detect_blob.cpp)|
|detect_mser|[detect_mser.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/detect_mser.cpp)|
|dft|[dft.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/dft.cpp)|
|digits_lenet|[digits_lenet.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/digits_lenet.cpp)|
|digits_svm|[digits_svm.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/digits_svm.cpp)|
|distrans|[distrans.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/distrans.cpp)|
|dis_opticalflow|[dis_opticalflow.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/dis_opticalflow.cpp)|
|drawing|[drawing.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/drawing.cpp)|
|edge|[edge.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/edge.cpp)|
|ela|[ela.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/ela.cpp)|
|em|[em.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/em.cpp)|
|facedetect|[facedetect.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/facedetect.cpp)|
|facial_features|[facial_features.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/facial_features.cpp)|
|falsecolor|[falsecolor.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/falsecolor.cpp)|
|fback|[fback.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/fback.cpp)|
|ffilldemo|[ffilldemo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/ffilldemo.cpp)|
|filestorage|[filestorage.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/filestorage.cpp)|
|fitellipse|[fitellipse.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/fitellipse.cpp)|
|flann_search_dataset|[flann_search_dataset.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/flann_search_dataset.cpp)|
|grabcut|[grabcut.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/grabcut.cpp)|
|imagelist_creator|[imagelist_creator.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/imagelist_creator.cpp)|
|imagelist_reader|[imagelist_reader.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/imagelist_reader.cpp)|
|image_alignment|[image_alignment.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/image_alignment.cpp)|
|inpaint|[inpaint.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/inpaint.cpp)|
|intelligent_scissors|[intelligent_scissors.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/intelligent_scissors.cpp)|
|intersectExample|[intersectExample.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/intersectExample.cpp)|
|kalman|[kalman.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/kalman.cpp)|
|kmeans|[kmeans.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/kmeans.cpp)|
|laplace|[laplace.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/laplace.cpp)|
|letter_recog|[letter_recog.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/letter_recog.cpp)|
|lkdemo|[lkdemo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/lkdemo.cpp)|
|logistic_regression|[logistic_regression.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/logistic_regression.cpp)|
|mask_tmpl|[mask_tmpl.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/mask_tmpl.cpp)|
|matchmethod_orb_akaze_brisk|[matchmethod_orb_akaze_brisk.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/matchmethod_orb_akaze_brisk.cpp)|
|minarea|[minarea.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/minarea.cpp)|
|morphology2|[morphology2.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/morphology2.cpp)|
|neural_network|[neural_network.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/neural_network.cpp)|
|npr_demo|[npr_demo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/npr_demo.cpp)|
|opencv_version|[opencv_version.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/opencv_version.cpp)|
|pca|[pca.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/pca.cpp)|
|peopledetect|[peopledetect.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/peopledetect.cpp)|
|phase_corr|[phase_corr.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/phase_corr.cpp)|
|points_classifier|[points_classifier.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/points_classifier.cpp)|
|polar_transforms|[polar_transforms.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/polar_transforms.cpp)|
|qrcode|[qrcode.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/qrcode.cpp)|
|segment_objects|[segment_objects.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/segment_objects.cpp)|
|select3dobj|[select3dobj.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/select3dobj.cpp)|
|simd_basic|[simd_basic.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/simd_basic.cpp)|
|smiledetect|[smiledetect.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/smiledetect.cpp)|
|squares|[squares.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/squares.cpp)|
|stereo_calib|[stereo_calib.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/stereo_calib.cpp)|
|stereo_match|[stereo_match.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/stereo_match.cpp)|
|stitching|[stitching.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/stitching.cpp)|
|text_skewness_correction|[text_skewness_correction.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/text_skewness_correction.cpp)|
|train_HOG|[train_HOG.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/train_HOG.cpp)|
|train_svmsgd|[train_svmsgd.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/train_svmsgd.cpp)|
|travelsalesman|[travelsalesman.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/travelsalesman.cpp)|
|tree_engine|[tree_engine.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/tree_engine.cpp)|
|videocapture_basic|[videocapture_basic.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_basic.cpp)|
|videocapture_camera|[videocapture_camera.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_camera.cpp)|
|videocapture_gphoto2_autofocus|[videocapture_gphoto2_autofocus.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_gphoto2_autofocus.cpp)|
|videocapture_gstreamer_pipeline|[videocapture_gstreamer_pipeline.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_gstreamer_pipeline.cpp)|
|videocapture_image_sequence|[videocapture_image_sequence.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_image_sequence.cpp)|
|videocapture_intelperc|[videocapture_intelperc.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_intelperc.cpp)|
|videocapture_openni|[videocapture_openni.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_openni.cpp)|
|videocapture_starter|[videocapture_starter.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videocapture_starter.cpp)|
|videowriter_basic|[videowriter_basic.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/videowriter_basic.cpp)|
|warpPerspective_demo|[warpPerspective_demo.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/warpPerspective_demo.cpp)|
|watershed|[watershed.cpp](https://github.com/opencv/opencv/blob/master/samples/cpp/watershed.cpp)|

