var viewportWidth = screen.width;
var viewportHeight = screen.height-39;

if(device != 'ios'){
	viewportWidth = 320;
	viewportHeight = 480-39;
}

var tileSize = 256;
var zoom = 1;
var zoomLevel = 1;
var minBlockSize = 4;
var popupMinimum = 4;

var arrZoomsize = new Array();
					arrZoomsize[1] = 1;
					arrZoomsize[2] = 2;
					arrZoomsize[3] = 4;
					arrZoomsize[4] = 8;
					arrZoomsize[5] = 16;
					arrZoomsize[6] = 32;
					arrZoomsize[7] = 64;
					arrZoomsize[8] = 64;

var zoomSizes = [
					["",""],
					[motifWidth * minBlockSize * arrZoomsize[1], motifHeight * minBlockSize * arrZoomsize[1]],
					[motifWidth * minBlockSize * arrZoomsize[2], motifHeight * minBlockSize * arrZoomsize[2]],
					[motifWidth * minBlockSize * arrZoomsize[3], motifHeight * minBlockSize * arrZoomsize[3]],
					[motifWidth * minBlockSize * arrZoomsize[4], motifHeight * minBlockSize * arrZoomsize[4]],
					[motifWidth * minBlockSize * arrZoomsize[5], motifHeight * minBlockSize * arrZoomsize[5]],
					[motifWidth * minBlockSize * arrZoomsize[6], motifHeight * minBlockSize * arrZoomsize[6]],
					[motifWidth * minBlockSize * arrZoomsize[7], motifHeight * minBlockSize * arrZoomsize[7]],
					[motifWidth * minBlockSize * arrZoomsize[8], motifHeight * minBlockSize * arrZoomsize[8]]
				];

var dragging = false;
var stTop;
var stLeft;
var dragStartTop;
var dragStartLeft;
var prevZoomLevel;
var isTouch = ('ontouchstart' in window);


//主に拡大縮小で使用。ズーム前のXとYを保存する
var prevInnerDivX;
var prevInnerDivy;

//通常時のアクションを格納するオブジェクト
var normalActions;

var searchResult="";

var tItemPerPage=20;

var TIMELINE_URL='timeline.php';

function init(){
	setInnerDivSize(zoomSizes[zoomLevel][0], zoomSizes[zoomLevel][1]);

	createButton();
	$('#timeline').css({'display':'none'});

	$("#shadow").css({
		width:viewportWidth,
		height:viewportHeight
	});

	$("#outerDiv").width(viewportWidth);
	$("#outerDiv").height(viewportHeight);
	$("#searchPanel").width(viewportWidth);
	
	// 初期表示用
	var innerDiv = document.getElementById("innerDiv");
	var outerDiv = document.getElementById("outerDiv");
	checkTiles();

	var $setOuterDiv = $('#outerDiv');
	var scrollSpeed  = 300;

	normalActions = {'touchstart mousedown': function(e){

			if(isTouch && typeof (event) != "undefined"){
				e.preventDefault();
				dragStartLeft = (isTouch ? event.changedTouches[0].pageX : e.pageX);
				dragStartTop = (isTouch ? event.changedTouches[0].pageY : event.pageY);
			}else{
				// IE用
				if(!e){
					e = window.event;
				}
				dragStartLeft = e.clientX;
				dragStartTop = e.clientY;
			}
		
			var innerDiv = document.getElementById("innerDiv");
			innerDiv.style.cursor = "-moz-grab";
			
			stTop = innerDiv.offsetTop;
			stLeft = innerDiv.offsetLeft;
			
			dragging = true;
			return false;
		},
		'touchmove mousemove': function(e){
			if(isTouch && typeof (event) != "undefined"){
				
				e.preventDefault();
				if(event.changedTouches[0] != undefined){
					moveX = (isTouch ? event.changedTouches[0].pageX : e.pageX);
					moveY = (isTouch ? event.changedTouches[0].pageY : e.pageY);
				}else{
					moveX = (isTouch ? e.originalEvent.changedTouches[0].pageX : e.pageX);
					moveY = (isTouch ? e.originalEvent.changedTouches[0].pageY : e.pageY);
				}
			}else{
				// IE用
				if(!e) e = window.event;
				moveX = e.clientX;
				moveY = e.clientY;
			}
			var innerDiv = document.getElementById("innerDiv");
			if(isTouch && typeof (event) != "undefined"){
				getMousePoint(event);
			}else{
				getMousePoint(e);
			}
			
			if(dragging){
				innerDiv.style.left = stLeft + (moveX - dragStartLeft) + 'px';
				innerDiv.style.top = stTop + (moveY - dragStartTop) + 'px';
			}
			checkTiles();
			
			viewNavi();
			
		},
		'touchend mouseup mouseout': function(e){
			var innerDiv = document.getElementById("innerDiv");
			innerDiv.style.cursor = "";
			
			var x;
			var y;
			if(isTouch && typeof (event) != "undefined"){
				e.preventDefault();
				if(event.changedTouches[0] != undefined){
					x = (isTouch ? event.changedTouches[0].pageX : e.pageX);
					y = (isTouch ? event.changedTouches[0].pageY : event.pageY);
				}else{
					x = (isTouch ? e.originalEvent.changedTouches[0].pageX : e.pageX);
					y = (isTouch ? e.originalEvent.changedTouches[0].pageY : e.pageY);
				}
			}else{
				// IE用
				if(!e){
					e = window.event;
					x=e.clientX;
					y=e.clientY;
				}
			}

			if(dragStartLeft == x && dragStartTop == y && $('#shadow').css('display') == 'none'){
				var ox=$('#innerDiv').position().left;
				var oy=$('#innerDiv').position().top;
				if (x >= ox && y>=oy && x <=zoomSizes[zoomLevel][0]+ox && y <= parseInt(zoomSizes[zoomLevel][1])+oy) {
					var xb=Math.floor((x-ox)/(minBlockSize*arrZoomsize[zoomLevel]));
					var yb=Math.round((y-oy)/(minBlockSize*arrZoomsize[zoomLevel]));
					yb=(yb == 1)?0:yb-1;
					xb++;
					var num=(motifWidth*yb)+xb;
					//alert(num);
					//alert(yb+"/"+xb+"/n:"+num);
					$.getJSON("swfData/search/search.php", { n: num},
					function(data){
					    if(data[0].result != "NOTFOUND"){
					    	scrollTo(0,1);
					    	setTimeout(addCursorToBlock, 100, data[0]['num']);
				  			moveToNum(data[0]['num']);
				  			searchResult=data[0];
				  			loadPopup();
					    }else{
					    	//alert("指定のNは見つかりませんでした。");
					    }
					});

				};
				dragging = false;
			}
		},
		'mouseout': function(e){
			var innerDiv = document.getElementById("innerDiv");
			innerDiv.style.cursor = "";
			dragging = false;
		}

	};
	$setOuterDiv.bind(normalActions);
	// IEでのドラッグに必要
	outerDiv.ondragstart = function(){ return false; }
	closeSearchPanel();
	if(sid != "") onSearchFromID(sid);
}

function createButton(){
	// zoomボタン
	$('#plusButton').css({
		//
		'top':viewportHeight-$('#plusButton').height()-180,
		'left':viewportWidth-$('#plusButton').width()-20,
		'zIndex':6000
	});
	$('#plusButton').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			toggleZoom('1');
		}
	});

	$('#minusButton').css({
		//
		'top':viewportHeight-$('#minusButton').height()-120,
		'left':viewportWidth-$('#minusButton').width()-20,
		'zIndex':6001
	});
	$('#minusButton').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			toggleZoom('-1');
		}
	});


	$('#homeButton').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			goBackToHome();
		}
	});
	$('#openSearchPanelButton').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			openSearchPanel();
		}
	});
	$('#closeSearchPanelButton').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			closeSearchPanel();
		}
	});
	$('#searchButton2').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			//alert($('#inputIdField').val());
			onSearchFromString('test');
			//ココ
			//onSearchFromID($('#inputIdField').val());
		}
	});
}

function goBackToHome(){
	//alert('back to home');
	if(zoomLevel != 1){
		var diff=1-zoomLevel;
		toggleZoom(diff);
	}
	$('#innerDiv').css({
		'left':0,
		'top':0
	});
	dragStartLeft = 0;
	dragStartTop = 0;
	setTimeout(checkTiles, 300);
}

function clearCursor(){
	var divs = innerDiv.getElementsByTagName("div");
	for(i = 0; i < divs.length; i++){
		var id = divs[i].getAttribute("class");
		if(id == 'searchCursor'){
			if(typeof divs[i] != "undefined"){
				innerDiv.removeChild(divs[i]);
			}
		}
	}	
}

function addCursorToBlock(resultN){
	clearCursor();

	var hh = arrZoomsize[zoomLevel]*minBlockSize;
	var ww = arrZoomsize[zoomLevel]*minBlockSize;
	resultN=parseInt(resultN);
	resultN--;

	var resultX=resultN;
	var resultY=0;
	if(resultN > motifWidth){
		resultX=resultN%motifWidth;
		resultY=Math.floor(resultN/motifWidth);
	}

	var cursor = $('<div />').
	  attr('class','searchCursor').
	  appendTo($('#innerDiv'));

	 cursor.css({
	 	'width':hh,
	 	'height':ww,
		'position':'absolute',
	 	'zIndex':1000,
	 	'top':(resultY*hh)-2,
	 	'left':(resultX*ww)-2
	 });
}

function openSearchPanel(){
	setTimeout(scrollTo, 100, 0, 1);
	$("#openSearchPanelButton").hide();
	$("#closeSearchPanelButton").show();
}
function closeSearchPanel(){
	setTimeout(scrollTo, 100, 0, 39);
	$("#closeSearchPanelButton").hide();
	$("#openSearchPanelButton").show();

}
function onStartSearch(value){
	onSearchFromID(value);
}
function onSearchFromID(value){
	if(value.length == 6){
		$('#searchButton2').unbind();
		$.getJSON("swfData/search/search.php", { id: value },
		function(data){
		    if(data[0].result != "NOTFOUND"){
		    	scrollTo(0,1);
		    	setTimeout(addCursorToBlock, 100, data[0]['num']);
	  			moveToNum(data[0]['num']);
	  			searchResult=data[0];
	  			loadPopup();
		    }else{
		    	alert("指定のID:"+value+"は見つかりませんでした。");
		    	setTimeout(bindSearchButton2, 1000);
		    }
		});
	}else{
		alert("6桁で入力してください。");
	}
}

function bindSearchButton2(){
	$('#searchButton2').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			e.preventDefault();
			
			onSearchFromID($('#inputIdField').val());
		}
	});
}


function onSearchFromString(value){
	//


	refleshTimeline();
}

function refleshTimeline(){
	//子ノード前削除
	$('#timeline').children().remove();

	$.ajax({
		type:"GET",
		dataType:"json",
		url:"swfData/search/timeline.json",
		success:function(data){
				$('#outerDiv').css({'display':'none'});
				$('#timeline').css({'display':'block'});

			    if(data[0] != ""){
			    	scrollTo(0,1);
			    	for(var i=0;i < data.length;i++){

						var tl = $('<div />').
						  attr('class','timelineChild').
						  attr('id','timelineChild'+data[i].id).
						  appendTo($('#timeline'));
						$('<img />').
						  attr('class','tlImg').
						  attr('src','swfData/blockimg/'+data[i].img+'.jpg').
						  load().
						  appendTo(tl);
						$('<div />').
						  attr('class','tlTitle').
						  html(data[i].b1).
						  appendTo(tl);
						$('<br />').
						  attr('class','timelineBR').
						  appendTo(tl);
						$('<div />').
						  attr('class','tlMsg').
						  html(data[i].b2).
						  appendTo(tl);
						$('<br />').
						  attr('class','timelineBR').
						  appendTo(tl);
						//tl.html("<img class='tlImg' src='swfData/blockimg/'"+data[i].img+"'.jpg'><div class='tlTitle'>"+data[i].b1+"</div><div class='tlMsg'>"+data[i].b2+"</div>");
			    	}
		  			//alert(data[0]['id']);
			    }else{
			    	alert("「"+value+"」では見つかりませんでした。");
			    	setTimeout(bindSearchButton2, 1000);
			    }
			}
	});



}

function moveToNum(resultN){
	var hh = arrZoomsize[zoomLevel]*minBlockSize;
	var ww = arrZoomsize[zoomLevel]*minBlockSize;
	resultN=parseInt(resultN);
	resultN--;
	//var resultN=300;
	var resultX=resultN;
	var resultY=0;
	if(resultN > motifWidth){
		resultX=resultN%motifWidth;
		resultY=Math.floor(resultN/motifWidth);
	}

	var nowPyramidCenterX=zoomSizes[zoomLevel][0]-(arrZoomsize[zoomLevel]*minBlockSize);
	var nowPyramidCenterY=zoomSizes[zoomLevel][1]-(arrZoomsize[zoomLevel]*minBlockSize);	

	var toX=(viewportWidth/2);//-(arrZoomsize[zoomLevel]*minBlockSize);
	var toY=(viewportHeight/2);//-(arrZoomsize[zoomLevel]*minBlockSize);
	$('#innerDiv').css({
		'left':toX-(resultX*ww)-(ww/2),
		'top':toY-(resultY*hh)-(hh/2)
	});
	zoomCheck();
}

function zoomCheck(){
	if(zoomLevel < 5){
		toggleZoom("1");
    	setTimeout(zoomCheck, 200);
	}else{
		checkTiles();
    	setTimeout(displayPopup, 300);
	}
}

function loadPopup(){
	$('#popup').html('');
	$('<img />').
		css('margin-top',5).
		attr('src','swfData/blockimg/'+searchResult['img']+'.jpg').
		load(function(){
		  	$('<div />').
		  		attr('id','popupOuterText').
		  		appendTo($('#popup'));
		  	$("#popupOuterText").css({'width':'80%','margin':'auto'});
			$("#popupOuterText").html('<p class="popupB1Style">'+searchResult['b1']+'</p><p class="popupB2Style">'+searchResult['b2']+'</p><img id="closeButton" src="./assets/buttons/close.png">');

			$("#closeButton").bind({'touchend mouseup mouseout':function(e){
					e.stopPropagation();
					e.preventDefault();
		//			alert("TAP!!!!");
					closePopup();
				}});

			var toY=$("#popup").height()-40;
		}).
		appendTo($('#popup'));
}
function displayPopup(){
	$("#shadow").css('display', 'block');
	$("#popup").css('display', 'block');

	var h=$("#popupOuterText").height()+$("#popupOuterText").offset().top+20;
	h = (h < viewportHeight+40)? viewportHeight+40:h;
	$("#shadow").css({'height': h});

}
function closePopup(){
	$('#searchButton2').unbind();
	$('#searchButton2').bind({'touchend mouseup': function(e){
			e.stopPropagation();
			e.preventDefault();
			onSearchFromID($('#inputIdField').val());
		}
	});
	$("#closeButton").unbind();
/*
	$("#shadow").unbind({'touchend mouseup mouseout':function(e){
			e.stopPropagation();
			//e.preventDefault();
//			alert("TAP!!!!");
			closePopup();
		}});
	$("#popup").unbind({'touchend mouseup mouseout':function(e){
			e.stopPropagation();
			//e.preventDefault();
//			alert("TAP!!!!");
			closePopup();
		}
	});
*/
	$("#popup").html('');
	setTimeout(scrollTo, 100, 0, 1);
	$("#shadow").css('display', 'none');
	$("#popup").css('display', 'none');
}

function viewNavi(){
	if(zoomLevel >= 2){
		var basicLeft = stripPx($("#navi").css("left"));
		var basicTop = stripPx($("#navi").css("top"));
		
		var thumbnailWidth = stripPx($("#navi").css("width"));
		var thumbnailHeight = stripPx($("#navi").css("height"));
		
		var startXpoint = stripPx(innerDiv.style.left) * -1;
		var startYpoint = stripPx(innerDiv.style.top) * -1;
		
		var zoomSize = arrZoomsize[zoomLevel];
		var levelOneXpoint = startXpoint / zoomSize;
		var levelOneYpoint = startYpoint / zoomSize;
		
		var levelOneWidth = motifWidth * 8;
		var levelOneHeight = motifHeight * 8;
		
		var thumbnailWidthRegio = thumbnailWidth / levelOneWidth;
		var thumbnailHeightRegio = thumbnailHeight / levelOneHeight;
		
		var naviXdist = levelOneXpoint * thumbnailWidthRegio;
		var naviYdist = levelOneYpoint * thumbnailHeightRegio;
		
		var naviWidth = viewportWidth * thumbnailWidthRegio / zoomSize;
		var naviHeight = viewportHeight * thumbnailWidthRegio / zoomSize;
		naviWidth = naviWidth + "px";
		naviHeight = naviHeight + "px";
		
		var naviXpoint = basicLeft + naviXdist;
		var naviYpoint = basicTop + naviYdist;
		
		$("#lens").css({"width": naviWidth, "height": naviHeight, "left": naviXpoint, "top": naviYpoint, "display" : "block"});
	}else{
		$("#lens").css({"display" : "none"});
	}
	
}


function moveCenter(event){
	var innerDiv = document.getElementById("innerDiv");
	innerDiv.style.top = event.clientY;
	innerDiv.style.left = event.clientX;
	
}

function getMousePoint(event){
	var innerDiv = document.getElementById("innerDiv");
	var p = getElementPosition(innerDiv);
	
	if(isTouch && typeof (event) != "undefined"){
		if(event.changedTouches != undefined){
			xx = (isTouch ? event.changedTouches[0].pageX : e.pageX) - p.x;
			yy = (isTouch ? event.changedTouches[0].pageY : event.pageY) - p.y;
		}

	}else{
		xx = event.clientX - p.x;
		yy = event.clientY - p.y;
	}

}

function getElementPosition(event){
	var p = {x:0,y:0};
	if( !event.offsetParent ){
		return p;
	}
	p.x = event.offsetLeft;
	p.y = event.offsetTop;
	if(event.offsetParent){
		var pp = getElementPosition(event.offsetParent);
		p.x += pp.x;
		p.y += pp.y;
	}
	return p;
}


function checkTiles(){
	$('#innerDiv').css({
		'width':zoomSizes[zoomLevel][0],
		'height':zoomSizes[zoomLevel][1]
	});

	var visibleTiles = getVisibleTiles();
	
	var innerDiv = document.getElementById("innerDiv");
	var visibleTilesMap = {};
	for(i = 0; i < visibleTiles.length; i++){
		var tileArray = visibleTiles[i];
		if(tileArray[0] < 0 || tileArray[1] < 0){
			continue;
		}
		var tileName =  "z" + zoomLevel  + "x" + tileArray[0] + "y" + tileArray[1];
		var tileDir = zoomLevel + "/" + tileArray[1] + "/";
		visibleTilesMap[tileName] = true;
		var img = document.getElementById(tileName);
		if(!img){
			img = document.createElement("img");
			img.src = blockimgDirPath + tileDir + tileName + ".jpg";
			img.style.position = "absolute";
			img.style.left = (tileArray[0] * tileSize) + "px";
			img.style.top = (tileArray[1] * tileSize) + "px";
			img.setAttribute("id", tileName);
			//$(tileName).css({'zIndex':-1});
			innerDiv.appendChild(img);
		}
	}
	
	var imgs = innerDiv.getElementsByTagName("img");
	for(i = 0; i < imgs.length; i++){
		var id = imgs[i].getAttribute("id");
		if(!visibleTilesMap[id]){
			if(typeof imgs[i] != "undefined"){
				innerDiv.removeChild(imgs[i]);
				i--;
			}
		}
	}
	if (searchResult != "") addCursorToBlock(searchResult['num']);
}

function getVisibleTiles(){
	var innerDiv = document.getElementById("innerDiv");
	
	var omX = 0;
	if(zoomSizes[zoomLevel][0] % tileSize != 0){
		omX = 1;
	}
	var omY = 0;
	if(zoomSizes[zoomLevel][1] % tileSize != 0){
		omY = 1;
	}
	var maxX = Math.abs(Math.floor(zoomSizes[zoomLevel][0] / tileSize)) + omX;
	var maxY = Math.abs(Math.floor(zoomSizes[zoomLevel][1] / tileSize)) + omY;

	var mapX = stripPx(innerDiv.style.left);
	var mapY = stripPx(innerDiv.style.top);
	
	var startX = Math.abs(Math.floor(mapX / tileSize)) - 1;
	var startY = Math.abs(Math.floor(mapY / tileSize)) - 1;
	
	var tilesX = Math.ceil(viewportWidth / tileSize) + 1;
	var tilesY = Math.ceil(viewportHeight / tileSize) + 1;
	
	var visibleTileArray = [];
	var counter = 0;
	
	var endX = tilesX + startX;
	var endY = tilesY + startY;
	
	if(endX > maxX){
		endX = maxX;
	}
	if(endY > maxY){
		endY = maxY;
	}
	
	for(x = startX; x < endX; x++){
		for(y = startY; y < endY; y++){
			visibleTileArray[counter++] = [x, y];
		}
	}
	return visibleTileArray;
}

function stripPx(value){
	if(value == "" || value == undefined){
		return 0;
	}
	if('string' != typeof value){
		value=String(value+"px");
	}
	return parseFloat(value.substring(0, value.length - 2));
}

function setInnerDivSize(width, height){
	$('#innerDiv').width(width);
	$('#innerDiv').height(height);
	//var innerDiv = document.getElementById("innerDiv");
	//innerDiv.style.width = width;
	//innerDiv.style.height = height;
}

function toggleZoom(zooming){
	prevZoomLevel=zoomLevel;
	zoomLevel = Number(zoomLevel) + Number(zooming);
	if(zoomLevel > arrZoomsize.length - 1){
		zoomLevel = arrZoomsize.length - 1;
		zooming = "";
	}else if(zoomLevel < 1){
		zoomLevel = 1;
		zooming = "";
	}
	zoom = arrZoomsize[zoomLevel];
	var innerDiv = document.getElementById("innerDiv");
	
	if(zooming == "1"){
		setPointZoomPlus(innerDiv, zoomLevel,zooming);
	}
	
	if(zooming == "-1"){
		setPointZoomMinus(innerDiv, zoomLevel,zooming);
	}
	
	var imgs = innerDiv.getElementsByTagName("img");
	while(imgs.length > 0){
		innerDiv.removeChild(imgs[0]);
	}
	setInnerDivSize(zoomSizes[zoomLevel][0], zoomSizes[zoomLevel][1]);
	
	checkTiles();
	
}


function setPointZoomPlus(innerDiv, zoomLevel,zooming){

	var pyramidPos = convertToGrobalCenterPos({"x":innerDiv.style.left,"y":innerDiv.style.top},zooming);
	if(zoomLevel != 8){
		var newPyramidPos = convertToLocalCenterPos({"x":pyramidPos.x*2,"y":pyramidPos.y*2},zooming);
	}else{
		var newPyramidPos = convertToLocalCenterPos({"x":pyramidPos.x,"y":pyramidPos.y},zooming);
	}

	innerDiv.style.left = newPyramidPos.x+"px";
	innerDiv.style.top =  newPyramidPos.y+"px";
}
function setPointZoomMinus(innerDiv, zoomLevel,zooming){
	var pyramidPos = convertToGrobalCenterPos({"x":innerDiv.style.left,"y":innerDiv.style.top},zooming);
	var newPyramidPos;

	if(zooming != "1" && prevZoomLevel != 8){
		newPyramidPos = convertToLocalCenterPos({"x":pyramidPos.x/2,"y":pyramidPos.y/2},zooming);
	}else if(prevZoomLevel == 8){
		newPyramidPos = convertToLocalCenterPos({"x":pyramidPos.x,"y":pyramidPos.y},zooming);
	}else{
		newPyramidPos = convertToLocalCenterPos({"x":pyramidPos.x/2,"y":pyramidPos.y/2},zooming);
	}
	innerDiv.style.left = newPyramidPos.x+"px";
	innerDiv.style.top =  newPyramidPos.y+"px";
}
function convertToGrobalCenterPos(pos,zooming){
	pos.x=stripPx(pos.x);
	pos.y=stripPx(pos.y);
	if(zooming == "1"){
		var prevPyramidWidth =  zoomSizes[zoomLevel-1][0];
		var prevPyramidHeight =  zoomSizes[zoomLevel-1][1];
	}else{
		if(zoomLevel != 1 || prevZoomLevel == 8){
			var prevPyramidWidth =  zoomSizes[zoomLevel][0];
			var prevPyramidHeight =  zoomSizes[zoomLevel][1];
		}else{
			var prevPyramidWidth =  zoomSizes[zoomLevel-1][0];
			var prevPyramidHeight =  zoomSizes[zoomLevel-1][1];
		}
	}
	var x = (pos.x + (prevPyramidWidth/2)) - (viewportWidth/2);
	var y = (pos.y + (prevPyramidHeight/2)) - (viewportHeight/2);
	
	return {"x":x,"y":y};
}

function convertToLocalCenterPos(pos,zooming){
	pos.x=stripPx(pos.x);
	pos.y=stripPx(pos.y);
	
	if(zooming == "1"){
		var nowPyramidWidth =  zoomSizes[zoomLevel][0];
		var nowPyramidHeight =  zoomSizes[zoomLevel][1];
	}else{
		if(zoomLevel != 1 && prevZoomLevel != 8){
			var nowPyramidWidth =  zoomSizes[zoomLevel-1][0];
			var nowPyramidHeight =  zoomSizes[zoomLevel-1][1];
		}else if(prevZoomLevel == 8){
			var nowPyramidWidth =  zoomSizes[zoomLevel][0];
			var nowPyramidHeight =  zoomSizes[zoomLevel][1];
		}else{
			var nowPyramidWidth =  zoomSizes[zoomLevel-1][0];
			var nowPyramidHeight =  zoomSizes[zoomLevel-1][1];
		}
	}
	
	var x =  pos.x - (nowPyramidWidth/2)+(viewportWidth/2);
	var y =  pos.y - (nowPyramidHeight/2)+(viewportHeight/2);
	
	return {"x":x,"y":y};
}

function setPoint(innerDiv, zoomLevel, rx, ry){
	
	cx = viewportWidth / 2;
	cy = viewportHeight / 2;
	s = arrZoomsize[zoomLevel];
	ms = arrZoomsize[zoomLevel - 1];
	x = cx;
	y = cy;
	
	if(typeof rx == "undefined"){
		rx = stripPx(innerDiv.style.left) * -1;
	}

	if(typeof ry == "undefined"){
		ry = stripPx(innerDiv.style.top) * -1;
	}
	
	if(typeof ms == "undefined"){
		xx = rx * -1;
		yy = ry * -1;
	}else{
		xx = cx + s * ((x + rx) / ms) * -1;
		yy = cy + s * ((y + ry) / ms) * -1;
	}
	
	innerDiv.style.left = xx;
	innerDiv.style.top =  yy;
}


function wheel(event){
	var delta = 0;
	if(!event){/* For IE. */
		event = window.event;
	}
	if(event.wheelDelta){ /* IE/Opera. */
		delta = event.wheelDelta/120;
		if (window.opera){
			delta = -delta;
		}
	}
	else if (event.detail){ /** Mozilla case. */
		delta = -event.detail/3;
	}
	if(delta){
		toggleZoom(delta);
	}
	
	if(event.preventDefault) {
		event.preventDefault();
	}
	event.returnValue = false;
}

if( typeof window.onmousewheel != 'undefined' ){
	window.onmousewheel = wheel;
}else if( window.addEventListener ){
	window.addEventListener( 'DOMMouseScroll', wheel, false );
}else{
	window.onmousewheel = document.onmousewheel = wheel;
}
