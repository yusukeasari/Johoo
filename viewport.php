<html>
<head>
<?php
$ua = $_SERVER['HTTP_USER_AGENT'];
if((strpos($ua,'iPhone')!==false)||(strpos($ua,'iPod')!==false)||(strpos($ua,'iPad')!==false)){
	print "<meta content=\"initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no\" name=\"viewport\" />";
}else if((strpos($ua,'Android')!==false)){
	if((strpos($ua,'Chrome')!==false)||(strpos($ua,'Firefox')!==false)){
		print "<meta content=\"initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no\" name=\"viewport\" />";
	}else{
		print "<meta content=\"target-densitydpi=device-dpi,user-scalable=no\" name=\"viewport\" />";
	}
}
?>
<meta content="yes" name="apple-mobile-web-app-capable" />
<link href="css/bootstrap.min.css" rel="stylesheet">
<link href="css/bootstrap-resposive.min.css" rel="stylesheet">
<link href="css/johoo.css" rel="stylesheet">

<script type="text/javascript" src="lib/jquery.js"></script>
<script type="text/javascript" src="lib/underscore.js"></script>
<script type="text/javascript" src="lib/backbone.js"></script>
<script type="text/javascript" src="lib/jquery.flickable-1.0b3.js"></script>

</head>
<body>
<div id="Shadow"></div>
<div id="Popup"></div>
<div id="Timeline"></div>
<div id="SearchPanel"></div>
<div id="ControlPanel">
	<div id="ZoomInButton"></div>
	<div id="ZoomOutButton"></div>
	<div id="SearchPanelButton"></div>
	<div id="TimelineButton"></div>
</div>
<div id="Pyramid">
	<div id="Tiles"></div>
</div>


<script src="app/pyramid2.js"></script>
<script src="js/bootstrap.min.js"></script>
</body>
</html>
