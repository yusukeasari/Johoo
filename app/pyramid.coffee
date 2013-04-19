$ ->
	#外部設定予定
	tilesX = 3
	tilesY = 4
	tileWidth = 512
	tileHeight = 512
	blockWidth = 20
	blockHeight = 20
	nowZoom = 1
	tileImageDir = 'swfData/'
	tileImageExtension = '.jpg'

	class PyramidModel extends Backbone.Model
		initialize:->
			alert "PyramidModelRENDER"

	class PyramidView extends Backbone.View
		initialize:->
			#このへんはCSSに書く予定
			$('#pyramid').css({'background-color':'#CCCCCC','width':1000,'height':600,'position':'relative','overflow':'hidden','border':'1px solid black'})

			$('<div />').
				attr('id','Tiles').
				css({'width':'100','height':'100','background-color':'#FF0000','position':'relative'}).
				appendTo $('#pyramid')

			tiles = new Tiles
			$('#pyramid').append tiles

	class Tile extends Backbone.View
		initialize:(x,y)->
			url = tileImageDir + 'z' + nowZoom + 'x' + x + 'y' + y + tileImageExtension

			$('<img />').
				attr('id','z'+nowZoom+'x'+x+'y'+y).
				attr('src', url).
				css({'position':'absolute','left':x*tileWidth,'top':y*tileWidth}).
				appendTo $('#Tiles')
		remove:->

	class Tiles extends Backbone.Collection
		initialize:->
			x=0
			y=0

			while y < tilesY
				while x < tilesX
					tile = new Tile x,y
					x++
				y++
				x=0

		method:->
			#
			#

	class Pyramid extends Backbone.View
		initialize:->
			model = new PyramidModel
			view = new PyramidView

	pyramid = new Pyramid
