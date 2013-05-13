/*
 * delval - Delete target input's value
 * 5509 - norimania[at]gmail.com
 * License - MIT
 * Archive - http://moto-mono.net/delval
 * Required - jQuery
 * Date - 09-06-02 13:15
*/

$.fn.delval=function(){$(this).each(function(c){var a=$(this);a.replaceWith("<span id='delval-"+c+"'></span>");$("span#delval-"+c).append(a).append("<span class='delval'></span>").addClass("delval-group");var d=$("span#delval-"+c).css("height",a.attr("offsetHeight")),b=$("span.delval",d).css("height",d.height());if(a.val().length<1){b.hide();}a.keyup(function(){if(a.val().length>0){b.show();}else{b.hide();}});b.click(function(){a.val("");b.hide();a.focus();});});};