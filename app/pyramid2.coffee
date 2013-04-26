#外部設定予定
tileWidth = 256
tileHeight = 256
blockWidth = 20
blockHeight = 20
minZoom = 1

motifWidth = 56
motifHeight = 60

pinchTrigger = 15

maxSearchResultNum = 50

searchPhp = 'swfData/search.php'
tileImageDir = 'swfData/web/'
zoomImageDir = 'swfData/blockimg/'
tileImageExtension = '.jpg'

minBlockSize = 1
arrZoomSizeX = [13,13,26,52,104,208]
arrZoomSizeY = [9,9,18,36,72,144]

#外部設定予定 ここまで
nowZoom = minZoom
prevZoom = minZoom
zoomSize = [
	[],
	[motifWidth * minBlockSize * arrZoomSizeX[1], motifHeight * minBlockSize * arrZoomSizeY[1]],
	[motifWidth * minBlockSize * arrZoomSizeX[2], motifHeight * minBlockSize * arrZoomSizeY[2]],
	[motifWidth * minBlockSize * arrZoomSizeX[3], motifHeight * minBlockSize * arrZoomSizeY[3]],
	[motifWidth * minBlockSize * arrZoomSizeX[4], motifHeight * minBlockSize * arrZoomSizeY[4]],
	[motifWidth * minBlockSize * arrZoomSizeX[5], motifHeight * minBlockSize * arrZoomSizeY[5]]
]

#ピンチイン/アウトのトリガーとなる距離配列を作る
pinchTriggerArray = []
i=1
for z in arrZoomSizeX
	pinchTriggerArray.push pinchTrigger*i
	i++

$ ->
	#処理開始
	pmviewer = new PhotomosaicViewer

#こっからクラス群

###*
 * Class PhotomosaicViewer メインクラス
 * 表示別にクラスを分けるようにすること
###
class PhotomosaicViewer extends Backbone.View
	initialize:->
		_.bindAll @

		#環境設定とか
		@uniBrowse = new Browser

		@shadow = new Shadow
		#フォトモザイク部分
		@pyramid = new Pyramid

		#拡大表示クラス
		@popup = new Popup

		@searchPanel = new SearchPanel

		#コンパネ ズームボタン、検索ウィンドウ表示ボタン、ヘルプ表示ボタンとか
		@controlPanel = new ControlPanel

		#フォトモザイク部分がクリックされ、かつ有効な座標であった場合、拡大表示を実行
		@pyramid.bind 'openPopupFromPoint',(p) => @popup.openPopupFromPoint p
		#コンパネイベント
		@controlPanel.bind 'change',(h) => @pyramid.update h
		@controlPanel.bind 'showSearchPanel', =>
			SearchPanel.show()
			Pyramid.hide()
			ControlPanel.hide()

class SearchPanel extends Backbone.View
	@el: '#SearchPanel'
	searchQuery: ''

	initialize:->
		_.bindAll @

		@timeline = new Timeline
		@timeline.bind 'add', @appendTimeline
		$(@el).bind 'onclicktimeline',@onclicktimeline

		@searchQuery = new SearchResult
		@loadingStatus = false
		@execSearched = false

		$(@el).load "searchPanel.html",null,(data,status) =>
			if status isnt 'success'
				alert "ERROR:検索パネルが読み込めません"
			else
				$(SearchPanel.el).html(data)
				@setup()

	onclicktimeline:(d)->
		console.log "onclicktimeline",d
	appendTimeline:(tile)->
		timelineChildView = new TimelineChildView model: tile
		$("#searchResult").append timelineChildView.render().el

	setup:->
		$('#searchSubmitButton').css {width:150,height:30}
		$('#searchSubmitButton').bind 'click',@onTapSubmitButton
		$(@el).bind 'bottom',@bottom

		$(window).scroll =>
			if $(document).height() < $(window).scrollTop()+Browser.height+4 and @loadingStatus is false and @execSearched
				@loading true
				$(@el).trigger 'bottom'

			#else if @loadingStatus and $(document).height() > $(window).scrollTop()+Browser.height-100
			#	@loading false

	bottom:=>
		#$('html,body').animate({scrollTop: $(selector).offset().top},'slow')
		setTimeout =>
			@sendQuery()
		, 1500

	loading:(bool)=>
		if bool
			$('#loadingAnimation').html('')
			$('#loadingAnimation').append('<img src="img/loadingAnimation.gif">')
			@loadingStatus = bool
		else
			$('#loadingAnimation').html('')
			$('#loadingAnimation').append('<span style="font-size:36px;">MORE RESULT</span>')
			@loadingStatus = bool

	onTapSubmitButton:->
		@execSearched = true
		@timeline.each @clear
		@searchQuery.resetPageCount()
		@sendQuery()

	sendQuery:->
		query = ''
		@searchQuery.unbind()
		@searchQuery.bind 'return',(result) => @render result
		@searchQuery.bind 'error', => @error

		#検索条件整形。とりあえず版に過ぎず、改良の余地あり。設定ファイルから読み込む方式にする事。
		if $('#SearchPanelInnerContents #id').val() isnt undefined
			query += 'id='+$('#SearchPanelInnerContents #id').val()+'&'
		if $('#SearchPanelInnerContents #b1').val() isnt undefined
			query += 'b1='+$('#SearchPanelInnerContents #b1').val()+'&'
		if $('#SearchPanelInnerContents #b2').val() isnt undefined
			query += 'b2='+$('#SearchPanelInnerContents #b2').val()+'&'

		if query isnt '' then query.slice 0,-1

		@searchQuery.sendQuery query

	error:=>
		@loading false

	render:(result)->
		if result isnt ""
			for item in result
				tlChild = new TimelineChild
				tlChild.set
					data:item
				@timeline.add tlChild
		else
			alert("「"+value+"」では見つかりませんでした。")
		@loading false

	@show:=>
		Shadow.show()
		$(@el).show()

	@hide:=>
		@execSearched = false
		@loadingStatus = false
		@timeline.each @clear
		Shadow.hide()
		$(@el).hide()
	clear:(tl)->
		tl.clear()

class Timeline extends Backbone.Collection
	model: TimelineChild

class TimelineChild extends Backbone.Model
	defaults:
		data: ''

	clear:->
		@destroy
		@view.unrender()

class TimelineChildView extends Backbone.View
	tagName: 'div'

	initialize:->
		#クラス内でthisを使うおまじない
		_.bindAll @

		@model.view = @;

	#tile描画に必要なhtml情報をreturnする
	render: =>
		item = @model.get 'data'
		tl = $(@el).
		  attr('class','timelineChild').
		  attr('id','timelineChild'+item.id)
		$('<img />').
		  attr('class','tlImg').
		  attr('width',80).
		  attr('src','swfData/blockimg/'+item.img+'.jpg').
		  load().
		  appendTo tl
		$('<div />').
		  attr('class','tlTitle').
		  html(item.b1).
		  appendTo tl
		$('<br />').
		  attr('class','timelineBR').
		  appendTo tl
		$('<div />').
		  attr('class','tlMsg').
		  html(item.b2).
		  appendTo tl
		$('<br />').
		  attr('class','timelineBR').
		  appendTo tl

		$(@el).bind 'click',@onclick

		@

	onclick:=>
		console.log 'click!!'
		@trigger 'onclicktimeline',@model.get 'data'

	unrender:=>
		$(@el).remove()
		$(@el).unbind()

class SearchResult extends Backbone.View

	page:1
	linePerPage:30

	sendQuery:(query)=>
		console.log 'Q:',query
		$.ajax "timeline.json",
			type:"GET"
			#data:query
			dataType:"json"
			error: (jqXHR, textStatus, errorThrown) ->
				@trigger 'error'
			success:(data) => @queryResult data

	queryResult:(result)=>
		@trigger 'return',result

	resetPageCount:=>
		@page = 1

	nextPage:=> @page++

###*
 * Class Browser 環境設定関連
 * ブラウザチェック、それにあわせた描画領域の設定、アドレスバーを隠す等
 * 完成したらちゃんと書く
###
class Browser extends Backbone.View
	@device: ''
	@os: ''
	@width: 0
	@height: 0
	@orient: 0

	initialize:->
		_.bindAll @
		#デバイスをチェック 縦横サイズ
		$(window).bind "orientationchange resize",@setup
		@setup()

	setup:->
		#iPhone or iPod
		if navigator.userAgent.match /iPhone/i or navigator.userAgent.match /iPod/i
			Browser.device = 'smartphone'
			Browser.os = 'ios'
			Browser.version = ''
			Browser.width = if Math.abs window.orientation isnt 90 then screen.width else screen.height
			Browser.height = if Math.abs window.orientation isnt 90 then screen.height-64 else screen.width-52

		#iPad
		else if navigator.userAgent.match /iPad/i
			Browser.device = 'tablet'
			Browser.os = 'ios'
			Browser.version = ''

		#Android Phone
		else if navigator.userAgent.match /Android/i and navigator.userAgent.match /Mobile/i
			Browser.device = 'smartphone'
			Browser.os = 'android'
			Browser.version = ''
			Browser.width = screen.width
			Browser.height = screen.height

		#Android Tablet
		else if navigator.userAgent.match /Android/i and not navigator.userAgent.match /Mobile/i
			Browser.device = 'tablet'
			Browser.os = 'android'
			Browser.version = ''
			Browser.width = screen.width
			Browser.height = screen.height

		#PC
		else
			Browser.device = 'pc'
			Browser.width = screen.width/2
			Browser.height = screen.height/2
		
		#描画範囲を決定
		$('#Pyramid').width Browser.width
		$('#Pyramid').height Browser.height

		#アドレスバーを隠す
		@hideAddressBar()

	#PC以外ならアドレスバーを隠す処理をおこなう
	hideAddressBar:->
		if Browser.getOS() is 'ios'
			setTimeout scrollTo,100,0,1
		else if Browser.getOS() is 'android'
			window.scrollTo 0,1

	@getDevice:=> @device
	@getOS:=> @os

class Utility
	@type = do ->
		classToType = {}
		for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
			classToType["[object " + name + "]"] = name.toLowerCase()
		(obj) ->
			strType = Object::toString.call(obj)
			classToType[strType] or "object"

###*
 * Class Pyramidクラス
###
class Pyramid extends Backbone.View
	el: "#Tiles"
	@outerel: '#Pyramid'

	###
	初期化メソッド
	###
	initialize:->
		#クラス内でthis(=@)を使うおまじない
		_.bindAll @

		if Browser.device isnt 'pc'
			$(@el).bind 'touchstart',@onMouseDown
			$(@el).bind 'touchend',@onMouseUp
			$(@el).bind 'touchmove',@onMouseMove
			#$(@el).bind 'gesturestart',@onGestureStart
			#$(@el).bind 'gesturechange',@onGestureMove
			#$(@el).bind 'gestureend',@onGestureEnd
			#
		else
			$(@el).bind 'mousedown',@onMouseDown
			$(@el).bind 'mouseup',@onMouseUp
			$(@el).bind 'mousemove',@onMouseMove

		$(@el).flickable()
		#Pyramid.el = @el

		#初期化
		@dragging = false

		@tiles = new Tiles
		@tiles.bind 'add', @appendTile
		@tiles.bind 'change', @changeTile

		$(@el).css {'cursor':'-moz-grab'}

		#初期画面を表示
		@update()
		@pyramidSetPositionToCenter()

	@show = ->
		$(@outerel).show()
	@hide = ->
		$(@outerel).hide()

	###
	マウスイベント関連メソッド群
	###
	onMouseDown:(e)->
		cords = Point.getPoint(e)
		e.preventDefault()
		@dragging = true

		if Utility.type(cords[0]) isnt 'array'
			$(@el).css {'cursor':'-moz-grab'}
			
			@dragStartX = cords[0]
			@dragStartY = cords[1]
			@dragStartPyramidX = @getPyramidPos()[0]

			@dragStartPyramidY = @getPyramidPos()[1]
		else if Utility.type(cords[0]) is 'array'
			$(@el).css {'cursor':'-moz-grab'}
			@pinchinStartCenterX = (cords[0][0] + cords[1][0])/2
			@pinchinStartCenterY = (cords[0][1] + cords[1][1])/2

			@pinchinStart = cords

	onMouseUp:(e)->
		cords = Point.getPoint e
		e.preventDefault()
		@dragging = false

		$(@el).css {'cursor':''}

		#マウスの位置がdownとupで変わらない＝単純クリックなら拡大表示実行
		if @dragStartX is cords[0] and @dragStartY is cords[1] and @isOnTiles [cords[0],cords[1]]
			#！！なぜか一行でいけないので！！　既に某か開かれていないかチェック
			if not Shadow.isShow()
				@trigger 'openPopupFromPoint',@getNumFromPoint [cords[0],cords[1]]
		else
			#フォトモザイクを描画
			@update()

	onMouseMove:(e)->
		cords = Point.getPoint e
		e.preventDefault()
		if Utility.type(cords[0]) is "number" and @dragging is true
			$(@el).css {'left':@dragStartPyramidX+(@getMousePos(e)[0]-@dragStartX),'top':@dragStartPyramidY+(@getMousePos(e)[1]-@dragStartY)}
		else if Utility.type(cords[0]) is "array" and @dragging is true
			#dx = @pinchinStartCenterX*2 - (cords[0][0]+cords[1][0])
			#dy = @pinchinStartCenterY*2 - (cords[0][1]+cords[1][1])
		else

	onGestureStart:(e)->
		console.log e.originalEvent.scale

	onGestureMove:(e)->
		if e.originalEvent.scale > 1
			@zoomIn e.originalEvent.scale
		else
			@zoomOut e.originalEvent.scale

	onGestureEnd:(e)->
		console.log e.originalEvent.scale

	zoomIn:(_z)->
		rate = Math.floor _z/2
		console.log "plus",rate,nowZoom
		if nowZoom < zoomSize.length-1
			prevZoom = nowZoom
			if nowZoom+rate < zoomSize.length-1
				nowZoom = nowZoom+rate
			else
				nowZoom = zoomSize.length-1
				
			if nowZoom isnt prevZoom
				@update 'pinchZoomIn'

	#ズームアウトボタンが押下された
	zoomOut:(_z)->
		_z = (_z-1)*10
		rate = Math.floor _z/2
		console.log "minus:",rate,nowZoom

		if nowZoom > minZoom
			prevZoom = nowZoom

			if nowZoom-rate > minZoom
				nowZoom = minZoom
			else
				nowZoom = nowZoom+rate

			if nowZoom isnt prevZoom
				@update 'pinchZoomOut'
				
	#与えられた座標がフォトモザイク上であるかどうか調べる
	isOnTiles:(p)->
		if p[0] >= @getPyramidPos()[0] && p[1]>=@getPyramidPos()[1] && p[0] <=zoomSize[nowZoom][0]+@getPyramidPos()[0] && p[1] <= parseInt(zoomSize[nowZoom][1])+@getPyramidPos()[1] then true else false

	getNumFromPoint:(p)->
		xb = Math.floor (p[0]-@getPyramidPos()[0])/arrZoomSizeX[nowZoom]
		yb = Math.round (p[1]-@getPyramidPos()[1])/arrZoomSizeY[nowZoom]
		yb = if yb is 0 or yb is 1 then 0 else yb-1
		xb++;
		
		motifWidth*yb+xb

	###*
	 * 描画範囲調査メソッド
	 * もっとスマートに出来たらなぁといつも思う
	###
	checkActiveTile:->
		#表示されている範囲の始点と終点のxy座標を調べる
		displayAreaStartX = if @getPyramidPos()[0] > 0 and Browser.width-Math.abs(@getPyramidPos()[0]) > 0 then 0 else Math.abs(@getPyramidPos()[0])
		displayAreaStartY = if @getPyramidPos()[1] > 0 and Browser.height-Math.abs(@getPyramidPos()[1]) > 0 then 0 else Math.abs(@getPyramidPos()[1])
		displayAreaEndX = if @getPyramidPos()[0]+zoomSize[nowZoom][0] > $('#Pyramid').width() then $('#Pyramid').width()-@getPyramidPos()[0] else zoomSize[nowZoom][0]
		displayAreaEndY = if @getPyramidPos()[1]+zoomSize[nowZoom][1] > $('#Pyramid').height() then $('#Pyramid').height()-@getPyramidPos()[1] else zoomSize[nowZoom][1]

		#マイナスはゼロとみなす
		displayAreaEndX = 0 if displayAreaEndX <= 0
		displayAreaEndY = 0 if displayAreaEndY <= 0

		#デバッグ用
		#console.log "D:",displayAreaStartX,displayAreaStartY,displayAreaEndX,displayAreaEndY,zoomSize[nowZoom][0],zoomSize[nowZoom][1]

		#タイル番号へ
		loadStartX = Math.floor displayAreaStartX/tileWidth
		loadStartY = Math.floor displayAreaStartY/tileHeight
		loadEndX = Math.floor displayAreaEndX/tileWidth
		loadEndY = Math.floor displayAreaEndY/tileHeight

		[loadStartX,loadStartY,loadEndX,loadEndY]

	###*
	 * 描画メソッド
	 * @param {startX} Number
	 * @param {startY} Number
	 * @param {endX} Number
	 * @param {endY} Number
	###
	render:(t)->
		x = t[0]
		y = t[1]
		x2 = t[2]
		y2 = t[3]

		@tiles.removeAllTiles()
		while y <= t[3]
			while x <= t[2]
				#一応重複チェック
				if not @tiles.isSameTile nowZoom,x,y
					tile = new Tile
					tile.set
						x:x
						y:y
						z:nowZoom
						display:true
					@tiles.add tile
				x++
			y++
			x=t[0]
		y = t[1]

	###*
	 * イベントコールバック用
	###
	update:(h)->
		#表示位置分岐
		switch h
			when 'zoomIn'
				@moveToZoomInPos()
			when 'zoomOut'
				@moveToZoomOutPos()
			when 'pinchZoomIn'
				@moveToPinchZoomInPos()
			when 'pinchZoomOut'
				@moveToPinchZoomOutPos()
			else

		$(@el).width zoomSize[nowZoom][0];
		$(@el).height zoomSize[nowZoom][1];
		@render @checkActiveTile()
	
	moveToPinchZoomInPos:->
		$(@el).css
			left:$(@el).position().left + @pinchinStartCenterX*-1
			top:$(@el).position().top + @pinchinStartCenterY*-1

	moveToPinchZoomOutPos:->
		$(@el).css
			left:$(@el).position().left + @pinchinStartCenterX/2
			top:$(@el).position().top + @pinchinStartCenterY/2

	moveToZoomInPos:->
		pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

		if nowZoom isnt zoomSize.length-1
			newPyramidPos = @convertToLocalCenterPos pyramidPos[0]*2,pyramidPos[1]*2
		else
			newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
		$(@el).css
			left:newPyramidPos[0]
			top:newPyramidPos[1]

	moveToZoomOutPos:->
		pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

		if prevZoom isnt 8
			newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[1]/2
		else if prevZoom is 8
			newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
		else
			newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[0]/2

		$(@el).css
			left:newPyramidPos[0]
			top:newPyramidPos[1]

	convertToGrobalCenterPos:(_x,_y)->
		if nowZoom isnt 1 or prevZoom is zoomSize.length-1
			console.log "GROBAL"
			prevPyramidWidth = zoomSize[prevZoom][0]
			prevPyramidHeight = zoomSize[prevZoom][1]
		else
			prevPyramidWidth = zoomSize[prevZoom][0]
			prevPyramidHeight = zoomSize[prevZoom][1]
			
		x = (_x+prevPyramidWidth/2)-Browser.width/2
		y = (_y+prevPyramidHeight/2)-Browser.height/2
		
		[x,y]

	convertToLocalCenterPos:(_x,_y)->
		#注意
		console.log _x,_y
		nowPyramidWidth =  zoomSize[nowZoom][0]
		nowPyramidHeight =  zoomSize[nowZoom][1]
		
		x =  _x - nowPyramidWidth/2+Browser.width/2
		y =  _y - nowPyramidHeight/2+Browser.height/2
		
		[x,y]

	###
	 * addイベントのコールバックメソッド
	 * 原則としてcollectionへbindする事
	 * @param {tile} Tile
	###
	appendTile:(tile)->
		tileView = new TileView model: tile
		$(@el).append tileView.render().el

	###
	Pyramid位置操作メソッド群
	###
	#中央寄せ処理
	pyramidSetPositionToCenter:->
		$(@el).css
			left:Browser.width/2 - zoomSize[nowZoom][0]/2;
			top:Browser.height/2 - zoomSize[nowZoom][1]/2;

	###
	 * 位置取得メソッド群
	 * 基本はreturnする簡単なお仕事
	 * @param {e} Event
	###
	getMousePos:(e)->
		cords = Point.getPoint(e)
		[cords[0],cords[1]]

	getPyramidPos:->
		[$(@el).position().left,$(@el).position().top]

###*
 * Tileクラス
 * Tile画像に必要な情報のみ保持するModelクラス
 * @param {x} Number
 * @param {y} Number
 * @param {z} Number
 * @param {display} Boolean
###
class Tile extends Backbone.Model
	defaults:
		x:0
		y:0
		z:0
		display:false
	clear:->
		@destroy
		@view.unrender()

###*
 * Class TileViewクラス Tile画像を描画したり削除する役割のみ
###
class TileView extends Backbone.View
	tagName: 'img'
	initialize:->
		#クラス内でthisを使うおまじない
		_.bindAll @

		@model.view = @;

	#tile描画に必要なhtml情報をreturnする
	render: =>
		x = @model.get 'x'
		y = @model.get 'y'
		z = @model.get 'z'
		url = tileImageDir + "#{z}/#{y}/" + 'z' + z + 'x' + x + 'y' + y + tileImageExtension
		$(@el).
			attr({id:'z'+z+'x'+x+'y'+y,src:url}).
			css({'position':'absolute','left':x*tileWidth,'top':y*tileWidth}).
			load()
		@

	unrender:=>
		$(@el).remove()

###*
 * Class Tiles Tileクラスを管理する役割。描画に関してのイベント管理とか。イベントの割り当ては原則、Pyramidクラスで行う
###
class Tiles extends Backbone.Collection
	model: Tile

	initialize:->
		_.bindAll @

	isSameTile:(_z,_x,_y)->
		data = []
		@each (tile) ->
			data.push tile
		for item in data
			if "#{item.get 'z'} #{item.get 'x'} #{item.get 'y'}" is "#{_z} #{_x} #{_y}"
				res = true
			else
				res = false
		res

	getNowVisibleList:->
		data = []
		@each (tile) ->
			data.push tile
		data

	setRemove:->
		data = []
		@each (tile) ->
			data.push tile

	removeCheckedTiles:->
		for tile in data
			if tile.get 'display' != true 
				tile.clear()

	removeAllTiles:->
		@each (tile) ->
			tile.clear()

###*
 * Class ControlPanel コンパネに表示するボタンとか管理
###
class ControlPanel extends Backbone.View
	@el: '#ControlPanel'

	initialize:->
		_.bindAll @

		#ズームインボタン
		zoomInButton = new ClickOnlyButton '#ZoomInButton'
		zoomInButton.bind 'change',@zoomIn

		#ズームアウトボタン
		zoomOutButton = new ClickOnlyButton '#ZoomOutButton'
		zoomOutButton.bind 'change',@zoomOut

		#検索パネル表示ボタン
		showSearchPanelButton = new ClickOnlyButton '#SearchPanelButton'
		showSearchPanelButton.bind 'change',@showSearchPanel

		#タイムラインパネル表示ボタン
		showTLPanelButton = new ClickOnlyButton '#TimelineButton'
		showTLPanelButton.bind 'change',@showTLPanel

	#ズームインボタンが押下された
	zoomIn:->
		if nowZoom < zoomSize.length-1
			prevZoom = nowZoom
			nowZoom++
			@trigger 'change','zoomIn'

	#ズームアウトボタンが押下された
	zoomOut:->
		if nowZoom > minZoom
			prevZoom = nowZoom
			nowZoom--
			@trigger 'change','zoomOut'

	#検索パネル表示ボタンが押下された
	showSearchPanel:->
		@trigger 'showSearchPanel'
		
	#タイムラインパネル表示ボタンが押下された
	showTLPanel:->
		#
	@show:=> $(@el).show()
	@hide:=> $(@el).hide()

#いまのところいらない子
class ControlPanelModel extends Backbone.Model

###*
 * Class ClickOnlyButton 汎用ボタンクラス。クラス名はちょっと考えたい。
 * @param div 描画用DOM
###
class ClickOnlyButton extends Backbone.View
	el: ''

	initialize:(_el)->
		_.bindAll @

		@el = _el
		$(@el).bind "mouseup touchend",@onMouseUp

	onMouseUp:(e)->
		e.preventDefault()
		@trigger 'change'

	destroy:->
		$(@el).unbind()
		$(@el).remove()

###*
 * Class Point イベントオブジェクトを受け取って座標を返すクラス。デバイス・ブラウザ問わずが基本思想
 * @param event マウスイベントオブジェクト
###
class Point
	#座標を取得
	@getPoint:(e)->
		if Point.isTouch()
			#SP or Tab
			#for Single Touch
			if e.originalEvent.touches.length is 1
				#座標をかえす
				console.log "SINGLE",e.originalEvent.touches[0].pageX,e.originalEvent.touches[0].pageY
				[e.originalEvent.touches[0].pageX,e.originalEvent.touches[0].pageY]

			#for Multi Touch
			else
				console.log "MULTI"
				cords = []
				for item in e.originalEvent.touches
					console.log item.pageX,item.pageY
					cords.push [item.pageX,item.pageY]
				#座標をかえす
				cords
		else
			#PC
			#座標をかえす
			[e.pageX,e.pageY]

	#タッチされている
	@isTouch:-> 'ontouchstart' of window

#テンポラリクラス
class Shadow extends Backbone.View
	@el: '#Shadow'

	initialize:->
		$(window).bind "load resize orientationchange",@resize

	@show:=>
		Shadow.setSize()
		$(@el).show()

	@hide:=>
		Shadow.setSize()
		$(@el).hide()

	resize:-> Shadow.setSize()

	@setSize:-> 
		$(@el).width Browser.width
		$(@el).height Browser.height

	@isShow:=>
		res = $(@el).css 'display'
		if res is 'none' then false else true

class Popup extends Backbone.View
	@el: '#Popup'

	initialize:->
		_.bindAll @
		$(window).bind "resize orientationchange",@resize

	openPopupFromPoint:(p)->
		$.getJSON searchPhp,{'n':p},(data,status)->
			#タップ拡大時に特殊なフラグによって条件分岐するならココ
			if status and data isnt null then Popup.render data[0]

	@clear:->
		#
		if $(Popup.el).html() isnt ''
			$("#closeButton").unbind()
			$(Popup.el).html ''

	@closePopup:(e)->
		if e isnt undefined
			e.stopPropagation()
			e.preventDefault()
		Popup.clear()
		Popup.hide()

	@render:(data)->
		Popup.show()
		$('<img />').
			css('margin-top',5).
			attr('src',zoomImageDir+data.img+'.jpg').
			load( ->
			  	$('<div />').
			  		attr('id','popupOuterText').
			  		appendTo $(Popup.el)
			  	$("#popupOuterText").css {'width':'80%','margin':'auto'}
			  	$('<p>').
			  		attr('class','popupB1Style').
			  		text(data.b1).
			  		appendTo $(Popup.el)
			  	$('<p>').
			  		attr('class','popupB2Style').
			  		text(data.b2).
			  		appendTo $(Popup.el)
			  	$('<img>').
			  		attr('id','closeButton').
			  		attr('src','assets/buttons/close.png').
			  		load( ->
			  			Popup.onClick()
			  		).
			  		appendTo $(Popup.el)
			).
			error( ->
				Popup.closePopup()
			).
			appendTo $(@el)

	@onClick:=>
		$("#closeButton").bind "touchend mouseup", (e)->
			e.stopPropagation()
			e.preventDefault()
			Popup.closePopup()

	@show:=>
		Shadow.setSize()
		$(@el).show()
		Shadow.show()

	@hide:=>
		Shadow.setSize()
		$(@el).hide()
		Shadow.hide()

	resize:-> Shadow.setSize()

	@setSize:-> 
		$(@el).width Browser.width
		$(@el).height Browser.height

	resize:->
		#	Browser.width = if Math.abs window.orientation isnt 90 then screen.width else screen.height
		#	Browser.height = if Math.abs window.orientation isnt 90 then screen.height-64 else screen.width-52
