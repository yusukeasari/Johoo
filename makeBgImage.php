<?php
/*
RewriteEngine on
RewriteCond %{REQUEST_FILENAME} .+bg_\w+\.(jpg|gif|png)$
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^.*bg_(\w+)\.(jpg|gif|png)$ /makeBgImage.php?id=$1 [R]
*/


if(!empty($_GET["id"])){
	if(!file_exists("sp/swfData/mosaic/{$_GET["id"]}/bg_{$_GET["id"]}.jpg")){
		$dirPath = "sp/swfData/mosaic/{$_GET["id"]}/web/1/";

		$im = new Imagick();

		$path = ".";
		$iterator = new DirectoryIterator($dirPath);
		$files = array();
		$width = 0;
		$height = 0;
		$mwidth = 0;
		$mheight = 0;

		foreach ($iterator as $file) {
			// ファイルがドットから始まっていない場合
			// ディレクトリは除く
			if (!$file->isDot() && $file->isDir()){
				$mwidth=0;
				foreach (new DirectoryIterator($file->getRealPath()) as $file2){
					if(!$file2->isDot() && !$file2->isDir()){
						$target = new Imagick($file2->getRealPath());

						$mwidth += $target->getImageWidth();

						array_push($files, array("image"=>$target,"width"=>$target->getImageWidth(),"height"=>$target->getImageHeight(),"name"=>$file2->getFilename()));
					}
				}
				$mheight += $target->getImageHeight();
				//
			}else if(!$file->isDot() && !$file->isDir()){
				array_push($files, $file->getRealPath().'/'.$file->getFilename);
			}
		}

		$target = new Imagick();

		//echo "{$mwidth}-{$mheight}";

		$target->newImage($mwidth, $mheight, 'none');

		$x=0;$y=0;
		foreach ($files as $image) {
			$x=substr($image["name"],3,1);
			$y=substr($image["name"],5,1);
			$target->compositeImage($image["image"], imagick::COMPOSITE_COPY, 256*$x, 256*$y);
		}

		$target->writeImage("sp/swfData/mosaic/{$_GET["id"]}/bg_{$_GET["id"]}.jpg");
		//$im->clear();
		//$im->destroy();
		//chmod('./uploads_orbi5000/text_img', 0666);
		header("Content-type: image/jpeg");
		echo file_get_contents("sp/swfData/mosaic/{$_GET["id"]}/bg_{$_GET["id"]}.jpg");
	}else{
		header("Content-type: image/jpeg");
		echo file_get_contents("sp/swfData/mosaic/{$_GET["id"]}/bg_{$_GET["id"]}.jpg");
	}
}
