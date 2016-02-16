<!DOCTYPE html>
<html>
<head>
<?php require_once 'viewport.php'; ?>
<meta name="apple-mobile-web-app-capable" content="yes">
<title>PITビューア</title>
<meta property="og:title" content='PITビューア'/>
<meta property="og:url" content="http://pearl.pitcom.jp/"/>
<meta property="og:image" content="http://pearl.pitcom.jp/fb.jpg"/>
<meta property="og:site_name" content='PITビューア'/>
<meta property="og:description" content='皆さまの写真でモザイクアートが完成しました！' />
</head>

<body>
<div id="Johoo">
	<div id="Shadow"></div>
	<div id="Popup"></div>
	<div id="Timeline"></div>
	<div id="SearchPanel"></div>
	<div id="ControlPanel">
		<div id="ZoomInButton"></div>
		<div id="ZoomOutButton"></div>
		<div id="SearchPanelButton"></div>
		<div id="HomeButton"></div>
		<div id="Logo"></div>
	</div>
	<!-- <div id="copy"></div> -->
	<div id="pitcomLogo" onclick="openLink('http://pitcom.jp/','PITCOMページを開きますか？')"></div>	
	<div id="SmallMap">
	</div>
	<div id="Pyramid">
		<div id="Tiles"></div>
	</div>
</div>

<script type="text/javascript" src="app/johoo.js"></script>
<!--[if lte IE 9]>
<script type="text/javascript" src="lib/jquery.ah-placeholder.js"></script>
<![endif]-->
<script type="text/javascript" src="lib/jquery.flickable-1.0b3.js"></script>
<script type="text/javascript" src="lib/jquery.bottom-1.0.js"></script>
<script>
function openLink(_url,_str){
	var openF = window.confirm(_str);
	if(openF){
		window.open(_url);
		return true;
	}else{
		return false;
	}
}

  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  // ga('create', '', 'auto');
  ga('require', 'displayfeatures');
  ga('send', 'pageview');

</script>
</body>
</html>
