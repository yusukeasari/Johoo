### 外部設定予定 ここから ###

tileWidth = 256
tileHeight = 256

#ズームアウト未実装
commentZoom = false

motifWidth = 70
motifHeight = 95

SEARCH_API = 'swfData/search.php'
TIMELINE_API = 'swfData/search.php'

tileImageDir = '/splitedge/blockimg/pituser/abenoharukas/web/'
zoomImageDir = 'swfData/blockimg/'

tileImageExtension = '.jpg'

INIT_FILE = 'init.php'

#0番目は適当に

### 外部設定予定 ここまで ###
### 以下原則変更不要 ###
pinchTrigger = 15
minBlockSize = 1
minZoom = 1
tlImageWidth = 80
nowZoom = minZoom
prevZoom = minZoom

initJson = {}

#ピンチイン/アウトのトリガーとなる距離配列を作る
zoomSize = []

getUrlVars = (_id)->
  vars = {}
  params = location.search.substring(1).split('&')

  for item in params
    #エスケープ要注意
    keySearch = item.search(/\=/)
    key = ''
    if keySearch isnt -1
      key = item.slice 0,keySearch
    val = item.slice(item.indexOf('=',0)+1)
    if key isnt ''
      vars[key] = decodeURI val
  vars[_id]

UID = getUrlVars 'uid'

DT = if getUrlVars 'dt' then getUrlVars 'dt' else 0

MID = getUrlVars 'mid'
initJsonPath = 'app/mid.json'

# DTあるなしでIMQとソリューションの切り分け
if DT isnt 0
  motifWidth = (if DT is "2" or DT is "4" then 45 else 50)
  motifHeight = (if DT is "2" or DT is "4" then 45 else 50)

  arrZoomSizeX = [0,4,8,16,32,64]
  arrZoomSizeY = [0,4,8,16,32,64]

  tileImageDir = 'swfData/mosaic/' + UID + '/web/'
  zoomImageDir = 'img/data/' + DT + '/orig_images_220/'

#こっからクラス群

###*
 * Class PhotomosaicViewer メインクラス
 * 表示別にクラスを分けるようにすること
###
class PhotomosaicViewer extends Backbone.View
  el: '#Johoo'

  initialize:=>
    #_.bindAll @
    #環境設定とか
    @uniBrowse = new Browser

    css_href = 'css/johoo_'+Browser.device+'.css?'+Utility.getRandom()

    $('<link>').
      attr('href',css_href).
      attr('rel','stylesheet').
      load().
      appendTo $('head')

    @setup("")
    
  onOrient:=>
    Shadow.setSize()
    #@smallMap.setup()
    @popup.resize()
    $(@el).show()
  openPopupFromPoint:(_id)=>
    p = 0
    $.getJSON SEARCH_API,{'id':_id},(data,status)=>
      #タップ拡大時に特殊なフラグによって条件分岐するならココ
      ##and "#{data.img}" isnt 'undefined' 
      if status and data isnt null
        p = data[0][0].num
        @popup.openPopupFromPoint p
        @marker.setResult p
        @marker.render()
    .fail ->
      console.log 'error:'+status

  openPopupFromTimeline:(_id)=>
    @popup.clear()
    @searchPanel.hide()
    #@smallMap.show()
    Pyramid.show()
    ControlPanel.show()

    nowZoom = arrZoomSizeX.length-2
    prevZoom = arrZoomSizeX.length-3

    @marker.setResult _id
    @pyramid.moveToNum _id

    #メイン画面へ戻る
  backtomain:=>
    @searchPanel.hide()
    @pyramid.closePopup()
    @popup.closePopup()
    Pyramid.show()
    ControlPanel.show()
    #検索パネル表示イベント
  showSearchPanel:=>
    #@popup.closePopup()
    @popup.clear()
    @searchPanel.show()
    #@smallMap.hide()
    Pyramid.hide()
    ControlPanel.hide()
#  closePopup:=>
#    @pyramid.closePopup()

  setup:(_init)=>
    #基底モデル
    @smodel = new SModel

    #半透明黒背景クラス
    @shadow = new Shadow

    #@smallMap = new SmallMap '#SmallMap','swfData/map.jpg'

    #フォトモザイク部分
    @pyramid = new Pyramid

    #拡大表示クラス
    @popup = new Popup

    #検索パネルクラス
    @searchPanel = new SearchPanel

    #検索パネルクラス
    @postPanel = new PostPanel

    #コンパネ ズームボタン、検索ウィンドウ表示ボタン、ヘルプ表示ボタンとか
    @controlPanel = new ControlPanel

    #検索位置を示すマーカー
    @marker = new Marker

    if Browser.device isnt 'pc'
      $(window).bind "orientationchange", =>
        $(@el).hide()
        
        setTimeout =>
          Browser.setup()
          @onOrient()
        ,1000
    else
      $(window).bind "resize", =>
        $(@el).hide()
        
        setTimeout =>
          Browser.setup()
          @onOrient()
        ,1000


    #フォトモザイク部分がクリックされ、かつ有効な座標であった場合、拡大表示を実行
    #@pyramid.bind 'openPopupFromPoint',(p) =>
    #  @popup.openPopupFromPoint p
    #  @marker.setResult p
    #  @marker.render()
    #メイン画面へ戻る
    @searchPanel.bind 'backtomain', =>
      @router.navigate "",
        trigger: true

    @popup.bind 'closePopup', =>
      @router.navigate "",
        trigger: true

    @pyramid.bind 'openPopupFromPoint',(_p) =>

      $.getJSON SEARCH_API,{'n':_p},(data,status)=>
        #タップ拡大時に特殊なフラグによって条件分岐するならココ
        if status and data isnt null
          if data[0].id isnt undefined
            p = data[0].id
            @router.navigate "mosaic/#{p}/",
              trigger: true

      .fail ->
        console.log 'error:'+status

    #検索パネル表示イベント
    @controlPanel.bind 'showSearchPanel', =>
      @router.navigate "search/",
        trigger: true

    #検索位置を示すマーカーを表示
    @pyramid.bind 'marker', =>
      @marker.render()

    #検索開始イベント
    @searchPanel.bind 'startSearch', =>
      @marker.clear()

    #タイムラインクリック時のイベント
    @searchPanel.bind 'onclicktimeline',(d) =>
      @router.navigate "timeline/#{d}/",
        trigger: true

    @pyramid.bind 'moving',(c) =>
      #@smallMap.setCoords c
    #コンパネイベント
    @controlPanel.bind 'change',(h) =>
      @pyramid.update h

    #フォトモザイクを標準位置へセット
    @controlPanel.bind 'onclickhomebutton', =>
      nowZoom = 1
      prevZoom = 2
      @pyramid.update()
      @pyramid.pyramidSetPositionToCenter()
      setTimeout =>
        @pyramid.update()
      , 100

    #投稿パネル表示イベント
    @controlPanel.bind 'showPostPanel', =>
      @searchPanel.hide()
      @postPanel.show()
      #@smallMap.hide()
      Pyramid.hide()
      ControlPanel.hide()

    Browser.setup()
    @onOrient()
    @controlPanel.trigger 'onclickhomebutton'

    ###
    # Router振り分け
    ###

    @router = new Backbone.Router
    @router.route "mosaic/:id/", (_id)=> @openPopupFromPoint(_id)
    @router.route "timeline/:id/", (_id)=> @openPopupFromTimeline(_id)
    @router.route "search/", (_p)=> @showSearchPanel()
    @router.route "", => @backtomain()

    Backbone.history.start()

class SmallMap extends Backbone.View
  el: ''
  cursor: '#smallMapCursor'
  image: '#smallMapImage'
  m:4
  dm:1

  initialize:(_el,_url)=>
    @el = _el

    @dm = if Browser.device is 'smartphone' then 1 else 2
    @m = @m/@dm

    $(@el).css
      'overflow':'hidden'
      'background-image':"url('"+_url+"')"
      'background-repeat':'no-repeat'
      'background-size':zoomSize[1][0]/@m+' '+zoomSize[1][1]/@m

    $('<div>').
      attr('id','smallMapCursor').
      appendTo $(@el)

    @setup()

  setup:=>
    @defaultRatio = [@m/zoomSize[1][0],@m/zoomSize[1][1]]

    $(@cursor).css
      width:Browser.width/@m
      position:'relative'
      height:Browser.height/@m
      border:'solid 1px #FF0000'
      zIndex:40
      left:20
      top:50

    $(@el).css
      #left:Browser.width-(zoomSize[1][0]/@m)-10
      top:Browser.height-(zoomSize[1][1]/@m)-10
      width:zoomSize[1][0]/@m
      height:zoomSize[1][1]/@m

    @setCoords([Browser.width/2 - zoomSize[nowZoom][0]/2,Browser.height/2 - zoomSize[nowZoom][1]/2])

  setCoords:(c)=>
    $(@cursor).css
      left:(c[0]/(@m*(zoomSize[nowZoom][0]/zoomSize[1][0])))*-1
      top:(c[1]/(@m*(zoomSize[nowZoom][1]/zoomSize[1][1])))*-1
      width:Browser.width/(@m*(zoomSize[nowZoom][0]/zoomSize[1][0]))
      height:Browser.height/(@m*(zoomSize[nowZoom][1]/zoomSize[1][1]))
      
  hide:=>
    $(@el).hide()
  show:=>
    $(@el).show()

  #setCursolSize:=>
    # コレが基準
    #@cursor.width(Browser.width*(zoomSize[nowZoom][0]/Browser.width))
    #@cursor.height(Browser.height*(zoomSize[nowZoom][1]/Browser.height))

###*
 * Class SModel 現在はイベント管理のみ
###
class SModel extends Backbone.Model
  setEvent:(_target,_eventname)=>
    @.bind _eventname,(_data) =>
      @cEvent(_eventname,_data)

  removeEvent:(_e)=>
    @.unbind _e

  cEvent:(_event,_data)=>
    @trigger "#{_event}R",_data

class PostPanel extends Backbone.View
  el: '#PostPanel'

  initialize:->
    #_.bindAll @

  show:=>
    $('<iframe>').
      attr('id','postLoadArea').
      attr('src','post.html').
      attr('width',300).
      attr('height',340).
      appendTo @el
    $(@el).show()

  hide:=>
    $(@el).html('')
    $(@el).hide()

class SearchPanel extends Backbone.View
  el: '#SearchPanel'
  searchQuery: ''
  noMoreResult: false
  @timeline: ''

  initialize:=>
    #_.bindAll @

    #タイムラインを構築
    @timeline = new Timeline
    @timeline.bind 'add', @appendTimeline
    @timeline.bind 'onclicktimeline',@onclicktimeline

    @searchQuery = new SearchResult
    @loadingStatus = false
    @execSearched = false

    $(@el).load "/searchPanel.html",@searchpanelloaded 

  searchpanelloaded:(data,status)=>
    if status isnt 'success'
      alert "ERROR:検索パネルが読み込めません"
    else
      $(SearchPanel.el).html(data)
    $('#backToMainButton').bind 'click', @onBackToMain
    @setup()

  onBackToMain:=>
    @trigger 'backtomain'

  onclicktimeline:(d)=>
    @clear()
    @trigger 'onclicktimeline',d

  appendTimeline:(tile)=>
    timelineChildView = new TimelineChildView model: tile

    $("#searchResult").append timelineChildView.render().el
    $('.tlTitle').css
      width:Browser.width-tlImageWidth-10
    $('.tlMsg').css
      width:Browser.width-tlImageWidth-10
    
  setup:=>
    #検索ボタンを有効化
    $('#searchSubmitButton').bind 'click', @onTapSubmitButton

    #ボタンリスト(MVCは？)
    deleteValueButtons = []
    $('span.delig').each (i,o)->
      deleteValueButtons.push new DeleteValueButton $(@)
    $('input[type=text]').each (i,o)->
      console.log @,o,i
      $(@).bind 'keyup', @inputKeyup

    #「続きを読む」を有効化
    $(@el).bind 'bottom',@bottom

    #スクロールされたら自動読み込み。現在凍結中。
    #$(window).scroll =>
    #  if $(document).height() < $(window).scrollTop()+Browser.height+4 and @loadingStatus is false and @execSearched
    #    @loading true
    #    $(@el).trigger 'bottom'
  inputKeyup:(e)=>
    alert e.keyCode
    if e.keyCode is 13
      @onTapSubmitButton()
      $(o).blur()

  bottom:=>
    setTimeout =>
      @sendQuery()
    , 1500

  loading:(bool)=>
    if bool
      $('#loadingAnimation').html('')
      $('#loadingAnimation').append('<img src="img/loadingAnimation.gif">')
      $('#loadingAnimation').height 48
      @loadingStatus = bool
    else
      $('#loadingAnimation').html('')
      if @noMoreResult isnt true
        $('#loadingAnimation').append('<span style="font-size:24px;margin:auto;vertical-align: middle;">タップして続きを見る</span>')
        $('#loadingAnimation').height 48
        $('#loadingAnimation').bind 'click', =>
          @loading true
          $(@el).trigger 'bottom'
          $('#loadingAnimation').unbind()

      @loadingStatus = bool

  onTapSubmitButton:=>
    $('#searchResultError').html('')

    @noMoreResult = false
    @execSearched = true
    @clear()
    @searchQuery.resetPageCount()
    @sendQuery()

    @trigger 'startSearch'

  sendQuery:=>
    #query = 'uid='+UID+'&'
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

  error:(t)=>
    @noMoreResult = true
    $('#searchResultError').html t

  render:(result)=>
    ERROR = result[1][0].ERROR

    switch ERROR
      when 'TOOMUCHRESULT'
        @error '<br />検索結果が100件を超えました。<br />条件を指定しなおしてください。'

      when 'NOTFOUND'
        @error '<br />検索にヒットしませんでした。'

      when 'NOWORD'
        @error '<br />検索条件を指定してください。'

      else
        TOTAL = result[1][1].TOTAL
        result = result[0]
        $('#searchResultError').html TOTAL+'件ヒットしました。'
        if result.length < 10
          @noMoreResult = true

        if result isnt ""
          for item in result
            tlChild = new TimelineChild
            tlChild.set
              data:item
            @timeline.add tlChild
        else
          alert("「"+value+"」では見つかりませんでした。")

    @loading false

  show:=>
    if $('#searchSubmitButton')[0] isnt undefined
    #if $._data($('#searchSubmitButton')[0],'events') isnt undefined
      @clear()
      Shadow.show()
      $(@el).show()
      $('input[type=tel]').each =>
        $(@).focus()

      $('#loadingAnimation').show()
      $('#loadingAnimation').height 0
    else
      setTimeout =>
        @show()
      ,100

  hide:=>
    @execSearched = false
    @loadingStatus = false
    $('#loadingAnimation').hide()
    $('#loadingAnimation').html('')
    $('#loadingAnimation').height 0
    $('#searchResultError').html('')

    Shadow.hide()
    $(@el).hide()

  clear:=>
    @execSearched = false
    $('#loadingAnimation').html('')
    @timeline.clear()

class DeleteValueButton extends Backbone.View
  el: ''
  button: ''

  initialize:(_el)=>
    @el = _el

    $('<span>').
      attr('id',@el.children('input').attr('id')+'DelButton').
      appendTo @el

    $('#'+@el.children('input').attr('id')+'DelButton').css {'position':'relative','height':'22px','width':'22px','top':'2px','right':'25px','background-image':'url(img/delval.png)','cursor':'pointer','display':'inline-block','backgroundRepeat':'no-repeat','backgroundPosition':'center'}

    @el.children('input').bind 'keyup', =>
      if @el.children('input').val() is '' then $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0} else $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':1}
    $('#'+@el.children('input').attr('id')+'DelButton').bind 'click', =>
      @el.children('input').val('')
      $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0}
      $('#'+@el.children('input').attr('id')+'DelButton').focus()

    $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0}

class Timeline extends Backbone.Collection
  model: TimelineChild

  clear:=>
    @each (tlChild) =>
      tlChild.clear()

class TimelineChild extends Backbone.Model
  defaults:
    data: ''

  initialize:=>
    @bind 'onclicktimeline',@onclicktimeline

  clear:=>
    @unbind
    @destroy
    @view.unrender()

class TimelineChildView extends Backbone.View
  tagName: 'div'
  data: ''
  
  events:
    "click"  :  "onclicks"

  initialize:=>
    #クラス内でthisを使うおまじない
    #_.bindAll @
    
    @model.view = @;
    
  #tile描画に必要なhtml情報をreturnする
  render:=>
    item = @model.get 'data'
    @data = item

    tl = $(@el).
      attr('class','timelineChild').
      attr('id','timelineChild'+item.id)
    $('<img />').
      attr('class','tlImg').
      attr('width',tlImageWidth).
      attr('src',zoomImageDir+item.img+tileImageExtension).
      load().
      appendTo tl
    $('<div>').
      attr('class','tlTitle').
      html(item.b1).
      appendTo tl
    $('<br />').
      appendTo tl
    $('<div>').
      attr('class','tlMsg').
      #html(item.b2+"(#{item.id})").
      html(item.b2).
      appendTo tl
    $('<br />').
      attr('class','timelineBR').
      appendTo tl

    @

  unrender:=>
    $(@el).remove()
    $(@el).unbind()

  onclicks:=>
    @model.trigger 'onclicktimeline',@data.num

class SearchResult extends Backbone.View

  page:1
  linePerPage:30

  sendQuery:(query)=>
    if query isnt ''
      pageQuery = '&page='+@page
    else
      pageQuery = 'page='+@page

    $.ajax TIMELINE_API,
      type:"GET"
      data:query+pageQuery
      dataType:"json"
      error: (jqXHR, textStatus, errorThrown) =>
        @trigger 'error'
      success:(data) =>
        @nextPage()
        @queryResult data

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
  @bname:''
  @orientation:''
  @os: ''
  @width: 0
  @height: 0
  @orient: 0
  @displayFix: 0
  @browserNameList:[{"name":'chrome'},{"name":'safari'},{"name":'firefox'},{"name":'androidbrowser'},{"name":'opera'}]

  initialize:=>
    #_.bindAll @
    #デバイスをチェック 縦横サイズ
    Browser.setup()

  @setup:=>
    #alert navigator.userAgent
    #iPhone or iPod

    
    @orientation = if Math.abs(window.orientation == 90) then "h" else "v"

    if navigator.userAgent.match /iPhone/i or navigator.userAgent.match /iPod/i
      Browser.device = 'iphone'

    #iPad
    else if navigator.userAgent.match /iPad/i
      Browser.device = 'ipad'

    #Android Phone
    else if navigator.userAgent.match /Android/i and navigator.userAgent.match /Mobile/i
      Browser.device = 'androidphone'

    #Android Tablet
    else if navigator.userAgent.match /Android/i
      Browser.device = 'androidtablet'

    #PC
    else
      Browser.device = 'pc'

    Browser.width = $(window).width()
    Browser.height = $(window).height()


    #描画範囲を決定
    $('#Pyramid').width Browser.width
    $('#Pyramid').height Browser.height

    #アドレスバーを隠す
    Browser.hideAddressBar()
  @tests:(_var)=>

    for b in @browserNameList
      console.log _var
      if _var.toLowerCase().match(new RegExp(b.name))
        return b.name

  #PC以外ならアドレスバーを隠す処理をおこなう
  @hideAddressBar:=>
    if Browser.getOS() is 'ios'
      setTimeout scrollTo,100,0,1

  @getDevice:=> @device
  @getOS:=> @os

class Utility
  @type = do =>
    classToType = {}
    for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
      classToType["[object " + name + "]"] = name.toLowerCase()
    (obj) =>
      strType = Object::toString.call(obj)
      classToType[strType] or "object"

  #対角線を求める
  @getDiagonal:(_x,_y)=>
    if _x > 0 and _y > 0
      return Math.sqrt(Math.pow(_x,2)+Math.pow(_y,2))
    else
      return false

  #キャッシュ対策用乱数取得
  @getRandom:=>
    return Math.floor(Math.random()*10000)


###*
 * Class Pyramidクラス
###
class Pyramid extends Backbone.View
  @outerel: '#Pyramid'

  el: "#Tiles"
  searchHit: ''

  ###
  初期化メソッド
  ###
  initialize:->
    #クラス内でthis(=@)を使うおまじない
    #_.bindAll @

    if Browser.device isnt 'pc'
      $(@el).bind 'touchstart',@onMouseDown
      $(@el).bind 'touchend',@onMouseUp
      $(@el).bind 'touchmove',@onMouseMove
      #一旦コメントアウト
      $(@el).bind 'gesturestart',@onGestureStart
      $(@el).bind 'gesturechange',@onGestureMove
      $(@el).bind 'gestureend',@onGestureEnd
      
    else
      $(@el).bind 'mousedown',@onMouseDown
      $(@el).bind 'mouseup',@onMouseUp
      $(@el).bind 'mousemove',@onMouseMove

    #$(@el).flickable()

    #初期化
    @dragging = false

    @tiles = new Tiles
    @tiles.bind 'add', @appendTile
    
    $(@el).css {'cursor':'-moz-grab'}

    #背景を設定
    $(@el).css
      'background-image':"url('./makeBgImage.php')"
      'background-size':'contain'
      #'-webkit-transform':'scale(2)'
      #'-moz-transform':'scale(2)'
      #'-o-transform':'scale(2)'
      #'-ms-transform':'scale(2)'
      #'transform':'scale(2)'

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
  onMouseDown:(e)=>
    cords = Point.getPoint(e)
    Point.lock(e)

    if Point.isLock() is false
      $(@el).css
        transform:"scale(1)"
      e.preventDefault()

      @dragging = true

      if Utility.type(cords[0]) isnt 'array'
        $(@el).css {'cursor':'-moz-grab'}
        
        @dragStartX = cords[0]
        @dragStartY = cords[1]
        @dragStartLeft = $(@el).position().left
        @dragStartTop = $(@el).position().top
        @dragStartPyramidX = @getPyramidPos()[0]

        @dragStartPyramidY = @getPyramidPos()[1]
      else
        $(@el).css {'cursor':'-moz-grab'}
        
        @dragStartX = cords[0][0]/2+cords[1][0]/2
        @dragStartY = cords[0][1]/2+cords[1][1]/2
        @dragStartLeft = $(@el).position().left
        @dragStartTop = $(@el).position().top

        @dragStartPyramidX = @getPyramidPos()[0]

        @dragStartPyramidY = @getPyramidPos()[1]

    ###
    else if Utility.type(cords[0]) is 'array'
      $(@el).css {'cursor':'-moz-grab'}
      @pinchinStartCenterX = (cords[0][0] + cords[1][0])/2
      @pinchinStartCenterY = (cords[0][1] + cords[1][1])/2

      @pinchinStart = cords
    ###
  onMouseUp:(e)=>
    cords = Point.getPoint e

    if cords isnt undefined and Point.isLock() is false
      $(@el).css
        transform:"scale(1)"
      e.preventDefault()
      #e.stopPropagation()
      @dragging = false
      $(@el).css {'cursor':''}

      #マウスの位置がdownとupで変わらない＝単純クリックなら拡大表示実行
      
      cordx = if Utility.type(cords[0]) isnt 'array' then cords[0] else cords[0][0]
      cordy = if Utility.type(cords[1]) isnt 'array' then cords[1] else cords[0][1]

      #console.log cordx,cordy

      if @isSingleTap(@dragStartX,cordx) and @isSingleTap(@dragStartY,cordy)
        #！！なぜか一行でいけないので！！　既に某か開かれていないかチェック
        if not Shadow.isShow() and nowZoom > 3
          $(@el).unbind 'touchend',@onMouseUp
          @trigger 'openPopupFromPoint',@getNumFromPoint [cords[0],cords[1]]
      else if @isSingleTap(@dragStartX,cordx) and @isSingleTap(@dragStartY,cordy) and @isOnTiles [cords[0][0],cords[0][1]]
        #！！なぜか一行でいけないので！！　既に某か開かれていないかチェック
        if not Shadow.isShow() and nowZoom > 3
          $(@el).unbind 'touchend',@onMouseUp
          @trigger 'openPopupFromPoint',@getNumFromPoint [cords[0][0],cords[0][1]]
      else
        #alert 'else'
        #フォトモザイクを描画
        @update()

  onMouseMove:(e)=>
    cords = Point.getPoint e
    #Point.lock(e)

    if cords isnt undefined and Point.isLock() is false
      e.preventDefault()
      if Utility.type(cords[0]) is "number" and @dragging is true
        $(@el).css {'left':@dragStartPyramidX+(@getMousePos(e)[0]-@dragStartX),'top':@dragStartPyramidY+(@getMousePos(e)[1]-@dragStartY)}
        @trigger 'moving',[@dragStartPyramidX+(@getMousePos(e)[0]-@dragStartX),@dragStartPyramidY+(@getMousePos(e)[1]-@dragStartY)]
      else if Utility.type(cords[0]) is "array" and @dragging is true
        #dx = @pinchinStartCenterX*2 - (cords[0][0]+cords[1][0])
        #dy = @pinchinStartCenterY*2 - (cords[0][1]+cords[1][1])
      else

  onGestureStart:(e)=>
    if Point.isLock() is false
      $(@el).css
        transform:"scale(1)"

  onGestureMove:(e)=>
    if Point.isLock() is false
      localX = @dragStartX-@dragStartLeft
      localY = @dragStartY-@dragStartTop
      
      dx = (zoomSize[nowZoom][0]-(zoomSize[nowZoom][0]*e.originalEvent.scale))/2
      dx = (dx/e.originalEvent.scale)+(zoomSize[nowZoom][0]-localX)

      dy = (zoomSize[nowZoom][1]-(zoomSize[nowZoom][1]*e.originalEvent.scale))/2
      dy = (dy/e.originalEvent.scale)+(zoomSize[nowZoom][1]-localY)


      $(@el).css
        transform:"scale(#{e.originalEvent.scale}) translate(#{dx}px,#{dy}px)"
        left:(zoomSize[nowZoom][0]-localX)*-1+(@dragStartLeft)
        top:(zoomSize[nowZoom][1]-localY)*-1+(@dragStartTop)

  onGestureEnd:(e)=>
    if Point.isLock() is false
      $(@el).css
        left:@dragStartLeft
        top:@dragStartTop
        transform:"scale(1)"
      #zoomSize
      cnt = 0
      if e.originalEvent.scale > 1
        for item in zoomSize
          if zoomSize[nowZoom][0]*e.originalEvent.scale > item[0] and item[0] isnt ""
          else if item[0] isnt undefined
            break
          cnt++
      else
        for item in zoomSize
          if zoomSize[nowZoom][0]*e.originalEvent.scale < item[0]
            break
          cnt++

      if nowZoom isnt cnt and cnt < zoomSize.length
        prevZoom = nowZoom
        nowZoom = cnt
        @update 'pinchZoom'
      else if cnt > zoomSize.length-1
        prevZoom = nowZoom
        nowZoom = zoomSize.length-2
        @update 'pinchZoom'

  zoomIn:(_z)=>
    rate = Math.floor _z/2
    if nowZoom < zoomSize.length-1
      prevZoom = nowZoom
      if nowZoom+rate < zoomSize.length-1
        nowZoom = nowZoom+rate
      else
        nowZoom = zoomSize.length-1

  #ズームアウトボタンが押下された
  zoomOut:(_z)=>
    _z = (_z-1)*10
    rate = Math.floor _z/2

    if nowZoom > minZoom
      prevZoom = nowZoom

      if nowZoom-rate > minZoom
        nowZoom = minZoom
      else
        nowZoom = nowZoom+rate
        
  #与えられた座標がフォトモザイク上であるかどうか調べる
  isOnTiles:(p)=>
    if p[0] >= @getPyramidPos()[0] && p[1]>=@getPyramidPos()[1] && p[0] <=zoomSize[nowZoom][0]+@getPyramidPos()[0] && p[1] <= parseInt(zoomSize[nowZoom][1])+@getPyramidPos()[1] then true else false

  isSingleTap:(_a,_b)=>
    if _a+3 > _b and _b > _a-3 then true else false

  getNumFromPoint:(p)=>
    xb = Math.floor (p[0]-@getPyramidPos()[0])/arrZoomSizeX[nowZoom]
    yb = Math.round (p[1]-@getPyramidPos()[1]+(arrZoomSizeX[nowZoom]/2))/arrZoomSizeY[nowZoom]
    yb = if yb is 0 or yb is 1 then 0 else yb-1
    xb++;
    
    motifWidth*yb+xb

  ###*
   * 描画範囲調査メソッド
   * もっとスマートに出来たらなぁといつも思う
  ###
  checkActiveTile:=>
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
    loadEndX = if Math.floor displayAreaEndX/tileWidth is Math.floor zoomSize[nowZoom][0]/tileWidth then Math.floor(displayAreaEndX/tileWidth)-1 else Math.floor displayAreaEndX/tileWidth
    loadEndY = if Math.floor displayAreaEndY/tileHeight is Math.floor zoomSize[nowZoom][1]/tileHeight then Math.floor(displayAreaEndY/tileHeight)-1 else Math.floor displayAreaEndY/tileHeight

    [loadStartX,loadStartY,loadEndX,loadEndY]

  ###*
   * 描画メソッド
   * @param {startX} Number
   * @param {startY} Number
   * @param {endX} Number
   * @param {endY} Number
  ###
  render:(t)=>
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

    @trigger 'marker'

  ###*
   * イベントコールバック用
  ###
  update:(h)=>
    #表示位置分岐
    switch h
      when 'zoomIn'
        @moveToZoomInPos()
      when 'zoomOut'
        @moveToZoomOutPos()
      when 'pinchZoom'
        @moveToPinchZoomPos()
      else

    $(@el).width zoomSize[nowZoom][0];
    $(@el).height zoomSize[nowZoom][1];
    @render @checkActiveTile()

  ###*
   * Pyramidを指定numにあわせて移動させるメソッド
  ###
  moveToNum:(d)=>
    if d % motifWidth is 0
      tx = motifWidth * arrZoomSizeX[nowZoom] * -1
      ty = Math.floor((d / motifWidth)-1) * arrZoomSizeX[nowZoom] * -1
    else
      tx = d % motifWidth * arrZoomSizeX[nowZoom] * -1
      ty = Math.floor(d / motifWidth) * arrZoomSizeY[nowZoom] * -1

    $(@el).css
      left:(Browser.width/2)+tx+arrZoomSizeX[nowZoom]/2
      top:(Browser.height/2)+ty-arrZoomSizeY[nowZoom]/2
    setTimeout =>
      @update ''
    , 500

    @trigger 'moving',[(Browser.width/2)+tx+arrZoomSizeX[nowZoom]/2,(Browser.height/2)+ty-arrZoomSizeY[nowZoom]/2]

  moveToPinchZoomPos:=>
    if @dragStartTop isnt undefined and @dragStartLeft isnt undefined
      $(@el).css
        left:@dragStartLeft-((@dragStartX-@dragStartLeft)*(Math.pow(2,nowZoom-prevZoom)-1))
        top:@dragStartTop-((@dragStartY-@dragStartTop)*(Math.pow(2,nowZoom-prevZoom)-1))

      @trigger 'moving',[$(@el).position().left,$(@el).position().top]

  moveToZoomInPos:=>
    pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

    if nowZoom is zoomSize.length-1 and commentZoom is true
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
    else
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]*2,pyramidPos[1]*2

    $(@el).css
      left:newPyramidPos[0]
      top:newPyramidPos[1]
    @trigger 'moving',[newPyramidPos[0],newPyramidPos[1]]

  moveToZoomOutPos:=>
    pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

    if prevZoom isnt 8
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[1]/2
    else if prevZoom is 8
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
    else
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[1]/2

    $(@el).css
      left:newPyramidPos[0]
      top:newPyramidPos[1]
    @trigger 'moving',[newPyramidPos[0],newPyramidPos[1]]

  ###*
   * 座標コンバーター
  ###
  convertToGrobalCenterPos:(_x,_y)=>
    if nowZoom isnt 1 or prevZoom is zoomSize.length-1
      prevPyramidWidth = zoomSize[prevZoom][0]
      prevPyramidHeight = zoomSize[prevZoom][1]
    else
      prevPyramidWidth = zoomSize[prevZoom][0]
      prevPyramidHeight = zoomSize[prevZoom][1]
      
    x = (_x+prevPyramidWidth/2)-Browser.width/2
    y = (_y+prevPyramidHeight/2)-Browser.height/2
    
    [x,y]

  ###*
   * 座標コンバーター2
  ###
  convertToLocalCenterPos:(_x,_y)=>
    #注意
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
  appendTile:(tile)=>
    tileView = new TileView model: tile
    $(@el).append tileView.render().el

  ###
  Pyramid位置操作メソッド群
  ###
  #中央寄せ処理
  pyramidSetPositionToCenter:=>
    $(@el).css
      left:Browser.width/2 - zoomSize[nowZoom][0]/2
      top:Browser.height/2 - zoomSize[nowZoom][1]/2

    @trigger 'moving',[Browser.width/2 - zoomSize[nowZoom][0]/2,Browser.height/2 - zoomSize[nowZoom][1]/2]

  ###
   * 位置取得メソッド群
   * 基本はreturnする簡単なお仕事
   * @param {e} Event
  ###
  getMousePos:(e)=>
    cords = Point.getPoint(e)
    [cords[0],cords[1]]

  getPyramidPos:=>
    [$(@el).position().left,$(@el).position().top]
  closePopup:=>
    $(@el).bind 'touchend',@onMouseUp

class Marker extends Backbone.View
  result: ''

  clear:=>
    @result = ''
    $('#Marker').remove()

  setResult:(num)=>
    @result = num

  render:=>
    if @result isnt ''
      $('#Marker').remove()

      tx = (@result%motifWidth-1) * arrZoomSizeX[nowZoom]
      ty = Math.floor(@result/motifWidth)*arrZoomSizeY[nowZoom]

      if this.result % motifWidth is 0
        tx = (motifWidth-1) * arrZoomSizeX[nowZoom]
        ty = Math.floor((this.result / motifWidth)-1) * arrZoomSizeX[nowZoom]
      else
        tx = (this.result % motifWidth - 1) * arrZoomSizeY[nowZoom]
        ty = Math.floor(this.result / motifWidth) * arrZoomSizeY[nowZoom]

      if tx < 0
        tx = 0
    

      $('<div />').
        attr('id','Marker').
        appendTo $('#Tiles')

      weight = if Math.floor(nowZoom/2) < 1 then 1 else Math.floor(nowZoom/2)

      $('#Marker').css
        zIndex:3000
        width:arrZoomSizeX[nowZoom]-(2*weight)
        height:arrZoomSizeY[nowZoom]-(2*weight)
        left:tx
        top:ty-2
        border:'solid '+weight+'px #FF0000'
        'background-color':'rgba(255,0,0,0.4)'

      setTimeout =>
        @swap()
      , 1000

  swap:=>
    $('#Marker').css {'zIndex':3000}

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
  clear:=>
    @destroy
    @view.unrender()

###*
 * Class TileViewクラス Tile画像を描画したり削除する役割のみ
###
class TileView extends Backbone.View
  tagName: 'img'
  initialize:->
    #クラス内でthisを使うおまじない
    #_.bindAll @

    @model.view = @;

  #tile描画に必要なhtml情報をreturnする
  render: =>
    x = @model.get 'x'
    y = @model.get 'y'
    z = @model.get 'z'
    url = tileImageDir + "#{z}/#{y}/" + 'z' + z + 'x' + x + 'y' + y + tileImageExtension+"?"+Utility.getRandom()

    $(@el).
      attr({id:'z'+z+'x'+x+'y'+y,src:url}).
      css({'position':'absolute','left':x*tileWidth,'top':y*tileWidth}).
      load()
    @

  loadTile: =>


  unrender:=>
    $(@el).remove()

###*
 * Class Tiles Tileクラスを管理する役割。描画に関してのイベント管理とか。イベントの割り当ては原則、Pyramidクラスで行う
###
class Tiles extends Backbone.Collection
  model: Tile

  initialize:=>
    #_.bindAll @

  isSameTile:(_z,_x,_y)=>
    data = []
    @each (tile) =>
      data.push tile
    for item in data
      if "#{item.get 'z'} #{item.get 'x'} #{item.get 'y'}" is "#{_z} #{_x} #{_y}"
        res = true
      else
        res = false
    res

  getNowVisibleList:=>
    data = []
    @each (tile) =>
      data.push tile
    data

  setRemove:=>
    data = []
    @each (tile) =>
      data.push tile

  removeCheckedTiles:=>
    for tile in data
      if tile.get 'display' != true 
        tile.clear()

  removeAllTiles:=>
    @each (tile) =>
      tile.clear()

###*
 * Class ControlPanel コンパネに表示するボタンとか管理
###
class ControlPanel extends Backbone.View
  @el: '#ControlPanel'

  initialize:=>
    #_.bindAll @

    #ズームインボタン
    zoomInButton = new ClickOnlyButton {'el':'#ZoomInButton'}
    zoomInButton.bind 'change',@zoomIn

    #ズームアウトボタン
    zoomOutButton = new ClickOnlyButton {'el':'#ZoomOutButton'}
    zoomOutButton.bind 'change',@zoomOut

    #検索パネル表示ボタン
    showSearchPanelButton = new ClickOnlyButton {'el':'#SearchPanelButton'}
    showSearchPanelButton.bind 'change',@showSearchPanel

    #タイムラインパネル表示ボタン
    showHomeButton = new ClickOnlyButton {'el':'#HomeButton'}
    showHomeButton.bind 'change',@onclickhomebutton

    #投稿パネル表示ボタン
    showPostButton = new ClickOnlyButton {'el':'#PostPanelButton'}
    showPostButton.bind 'change',@showPostPanel

  #ズームインボタンが押下された
  zoomIn:=>
    if nowZoom < zoomSize.length-1
      prevZoom = nowZoom
      nowZoom++
      @trigger 'change','zoomIn'

  #ズームアウトボタンが押下された
  zoomOut:=>
    if nowZoom > minZoom
      prevZoom = nowZoom
      nowZoom--
      @trigger 'change','zoomOut'

  #検索パネル表示ボタンが押下された
  showSearchPanel:=>
    @trigger 'showSearchPanel'
    
  #タイムラインパネル表示ボタンが押下された
  onclickhomebutton:=>
    @trigger 'onclickhomebutton'

  #タイムラインパネル表示ボタンが押下された
  showPostPanel:=>
    @trigger 'showPostPanel'

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

  initialize:(_obj)=>
    #_.bindAll @
    el = _obj.el
    $(@el).unbind()

    if Browser.device isnt 'pc'
      $(@el).bind "touchend",@onMouseUp
    else
      $(@el).bind "mouseup",@onMouseUp

  onMouseUp:(e)=>
    e.preventDefault()
    @trigger 'change'

  destroy:=>
    $(@el).unbind()
    $(@el).remove()

###*
 * Class Point イベントオブジェクトを受け取って座標を返すクラス。デバイス・ブラウザ問わずが基本思想
 * @param event マウスイベントオブジェクト
###
class Point
  @locked: false
  @plock:0

  @lock:(e)=>
    if e.originalEvent.touches isnt undefined
      if e.originalEvent.touches.length > 2 and @plock < 3
        @locked = true
      else
        @locked = false
      @plock = e.originalEvent.touches.length
    else
      @locked = false
      @plock = 1
  @isLock:=>
    @locked
  #座標を取得
  @getPoint:(e)=>
    if Point.isTouch()
      #SP or Tab
      #for Single Touch
      if e.originalEvent.touches.length is 1
        #座標をかえす
        [e.originalEvent.touches[0].pageX,e.originalEvent.touches[0].pageY]

      #for Multi Touch
      else if e.originalEvent.touches.length > 1
        cords = []
        ftime = false
        for item in e.originalEvent.touches
          if item.pageX > hx and ftime is true
            hx = item.pageX
          else if ftime is false
            hx = item.pageX
          if item.pageX < lx and ftime is true
            lx = item.pageX
          else if ftime is false
            lx = item.pageX
          if item.pageY > hy and ftime is true
            hy = item.pageY
          else if ftime is false
            hy = item.pageY
          if item.pageY < ly and ftime is true
            ly = item.pageY
          else if ftime is false
            ly = item.pageY

          ftime = true
        #座標をかえす
        cords.push [hx,hy]
        cords.push [lx,ly]
        cords
      else
        [e.originalEvent.changedTouches[0].pageX,e.originalEvent.changedTouches[0].pageY]
    else
      #PC
      #座標をかえす
      [e.pageX,e.pageY]

  #タッチされている
  @isTouch:=> 'ontouchstart' of window

#テンポラリクラス
class Shadow extends Backbone.View
  @el: '#Shadow'

  @show:=>
    Shadow.setSize()
    $(@el).show()

  @hide:=>
    Shadow.setSize()
    $(@el).hide()

  resize:=> Shadow.setSize()

  @setSize:=> 
    $(@el).width Browser.width
    $(@el).height Browser.height

  @setFullSize:(_h)=> 
    $(@el).width Browser.width
    if Browser.height >_h+20
      $(@el).height Browser.height
    else
      $(@el).height $(@el).height _h+20

  @isShow:=>
    res = $(@el).css 'display'
    if res is 'none' then false else true

class Popup extends Backbone.View
  el: '#Popup'

  initialize:->
    #_.bindAll @

  openPopupFromPoint:(p)=>
    #@show()
    Shadow.show()
    #$.getJSON SEARCH_API,{'n':p,'uid':UID},(data,status)=>
    $.getJSON SEARCH_API,{'n':p},(data,status)=>
      #タップ拡大時に特殊なフラグによって条件分岐するならココ
      ##and "#{data.img}" isnt 'undefined' 
      if status and data isnt null then @render data[0] else @hide()
    .fail ->
      @hide()

  clear:=>
    if $(@el).html() isnt ''
      $("#closeButton").unbind()
      $(@el).html ''

  closePopup:(e)=>
    if e isnt undefined
      e.preventDefault()
    @clear()
    @hide()

  render:(data)=>
    #Popup要素初期化
    $(@el).empty()
    $('<img />').
      css('margin-top',5).
      attr('src',zoomImageDir+data.img+tileImageExtension).
      load( =>
#        v = encodeURIComponent 'http://instantmosaiq.com/sp/sp.php?uid='+UID#+'&dt='+DT
#        v = encodeURIComponent "http://abenoharukas.pitcom.jp/sp.php#mosaic/#{data.id}/"
        vf = encodeURIComponent "http://abenoharukas.pitcom.jp/sp.php#mosaic/#{data.id}/?utm_source=facebook_sp_id&utm_medium=sosial&utm_campaign=abenoharukas"
        vt = encodeURIComponent "http://abenoharukas.pitcom.jp/sp.php#mosaic/#{data.id}/?utm_source=twitter_sp_id&utm_medium=sosial&utm_campaign=abenoharukas"
        $('<div />').
          attr('id','popupOuterText').
          appendTo $(@el)
        $("#popupOuterText").css {'width':'80%','margin':'auto'}
        $('<p>').
          attr('class','popupB1Style').
          html(data.b1).
          appendTo $(@el)
        $('<p>').
          attr('class','popupB3Style').
          html(data.b3).
          appendTo $(@el)
        $('<p>').
          attr('class','popupB4Style').
          html(data.b4).
          appendTo $(@el)
        $('<p>').
          attr('class','popupB2Style').
          html(data.b2+"(#{data.id})").
          appendTo $(@el)
        $('<p>').
          attr('class','popupSnsStyle').
          html('<a href="https://www.facebook.com/sharer.php?u='+vf+'" target="_blank" class="snsFacebookButton"><img src="assets/buttons/snsFacebookIcon.png"></a> <a href="https://twitter.com/intent/tweet?url='+vt+'" target="_blank" class="snsTwitterButton"><img src="assets/buttons/snsTwitterIcon.png"></a>').
          appendTo $(@el)
        $('<input>').
          attr('id','closeButton').
          attr('type','button').
          attr('value','閉じる').
          appendTo $(@el)
        # $('<input>').
        #   attr('id','mosaicButton').
        #   attr('type','button').
        #   attr('value','モザイクを見る').
        #   appendTo $(@el)
        @snsButtonAction(data.id)
        @mosaicButtonAction(data.mid)
        @closeButtonAction()

        @show()
      ).
      error( =>
        @closePopup()
      ).
      appendTo $(@el)
  snsButtonAction:(_id)=>
    $(".snsFacebookButton").bind "touchend",(e) =>
      #window.open('https://www.facebook.com/sharer.php?u=http://www.amwaylive.com/ctl/m/cam/msc_pc.html?cip=mscsnsr')
      _gaq.push(['_trackPageview', '/photomosaic/sp/fb/'+_id]);
      $(".snsFacebookButton").unbind()

    $(".snsTwitterButton").bind "touchend",(e) =>
      #window.open('https://twitter.com/?status=http://www.amwaylive.com/ctl/m/cam/msc_pc.html?cip=mscsnsr')
      _gaq.push(['_trackPageview', '/photomosaic/sp/tw/'+_id]);
      $(".snsTwitterButton").unbind()

    $(".snsLineButton").bind "touchend",(e) =>
      #window.open('https://line.naver.jp/R/msg/text/?http://www.amwaylive.com/ctl/m/cam/msc_pc.html?cip=mscsnsr')
      _gaq.push(['_trackPageview', '/photomosaic/sp/line/'+_id]);
      $(".snsLineButton").unbind()

  closeButtonAction:=>
    if Browser.device isnt 'pc'
      $("#closeButton").bind "touchend",(e) =>
        e.preventDefault()
        @closePopup(e)
        $("#closeButton").unbind()
    else
      $("#closeButton").bind "mouseup",(e) =>
        e.preventDefault()
        @closePopup(e)
        $("#closeButton").unbind()
  mosaicButtonAction:(_mid)=>
      $("#mosaicButton").bind "touchend",(e) =>
        location.href='mosaicView.php?mid='+ _mid
        $("#mosaicButton").unbind()
      $("#mosaicButton").bind "mouseup",(e) =>
        location.href='mosaicView.php?mid='+ _mid
        $("#mosaicButton").unbind()

  show:=>
    $(@el).show()
    Shadow.show()
    Shadow.setFullSize($(@el).height())

  hide:=>
    @trigger "closePopup"
    Shadow.setSize()
    $(@el).hide()
    Shadow.hide()

  resize:=> Shadow.setSize()

  @setSize:=> 
    $(@el).width Browser.width
    $(@el).height Browser.height
getSection = (url, callback) ->
  req = $.getJSON url
  req.success (data) ->
    callback(data)
setInitData = (data) ->
  tileWidth = data.tileWidth
  tileHeight = data.tileHeight
  motifWidth = data.motifWidth
  motifHeight = data.motifHeight
  arrZoomSizeX = data.arrZoomSize
  arrZoomSizeY = data.arrZoomSize
  tileImageDir = data.blockimgPath
  zoomImageDir = 'swfData/blockimg/'

  SEARCH_API = 'swfData/search.php'

  i=0
  for x in arrZoomSizeX
    zoomSize.push [motifWidth*minBlockSize*arrZoomSizeX[i],motifHeight*minBlockSize*arrZoomSizeY[i]]
    i++

  pmviewer = new PhotomosaicViewer

$(window).load =>
  getSection initJsonPath,setInitData
