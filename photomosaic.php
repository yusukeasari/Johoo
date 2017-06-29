<!DOCTYPE html>
<html>
<head>
	<?php require_once 'assets/viewport.php'; ?>
	<meta name="apple-mobile-web-app-capable" content="yes">
	<title></title>
	<meta name="description" content="">
	<meta property="og:title" content=''/>
	<meta property="og:url" content="http://SUBDOMAIN.pitcom.jp/"/>
	<meta property="og:image" content="http://SUBDOMAIN.pitcom.jp/fb.jpg"/>
	<meta property="og:site_name" content=''/>
	<meta property="og:description" content='' />
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
		</div>
		<!-- <div id="Logo"></div> -->
		<!-- <div id="copy"></div> -->
		<div id="pitcomLogo" onclick="openLink('http://pitcom.jp/','PITCOMページを開きますか？')"></div>
		<div id="Pyramid">
			<div id="Tiles"></div>
		</div>
	</div>

	<script type="text/javascript" src="lib/package.js"></script>

	<script type="text/javascript" src="app/johoo.js"></script>
	<!--[if lte IE 9]>
	<script type="text/javascript" src="lib/jquery.ah-placeholder.js"></script>
	<![endif]-->
	<script type="text/javascript" src="lib/jquery.flickable-1.0b3.js"></script>
	<script type="text/javascript" src="lib/jquery.bottom-1.0.js"></script>
	

</body>
</html>
