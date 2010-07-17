/**
*
* jquery.sparkline.js
*
* v1.0
* (c) Splunk, Inc
* Contact: Gareth Watts (gareth@splunk.com)
*
* Generates inline sparkline charts from data supplied either to the method
* or inline in HTML
*
* Compatible with Internet Explorer 6.0+ and modern browsers equipped with the canvas tag
* (Firefox 2.0+, Safari, Opera, etc)
*
* License: New BSD License
*
* Copyright (c) 2008, Splunk Inc.
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
*     * Redistributions of source code must retain the above copyright notice,
*       this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright notice,
*       this list of conditions and the following disclaimer in the documentation
*       and/or other materials provided with the distribution.
*     * Neither the name of Splunk Inc nor the names of its contributors may
*       be used to endorse or promote products derived from this software without
*       specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
* OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
* SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
* OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*
* Usage:
*  $(selector).sparkline(values, options)
*
* If values is undefined or set to 'html' then the data values are read from the specified tag:
*   <p>Sparkline: <span class="sparkline">1,4,6,6,8,5,3,5</span></p>
*   $('.sparkline').sparkline();
* There must be no spaces in the enclosed data set
*
* Otherwise values must be an array of numbers
*    <p>Sparkline: <span id="sparkline1">This text replaced if the browser is compatible</span></p>
*    $('#sparkline1').sparkline([1,4,6,6,8,5,3,5])
*
* Supported options:
*   lineColor - Color of the line used for the chart
*   fillColor - Color used to fill in the chart - Set to '' or false for a transparent chart
*   width - Width of the chart - Defaults to 3 times the number of values in pixels
*   height - Height of the chart - Defaults to the height of the containing element
*
* There are 3 types of sparkline, selected by supplying a "type" option of 'line' (default), 'bar' or 'tristate'
*    line - Line chart.  Options:
*       spotColor - Set to '' to not end each line in a circular spot
*       spotRadius - Radius in pixels
*
*   bar - Bar chart.  Options:
*       barColor - Color of bars for postive values
*       negBarColor - Color of bars for negative values
*       barWidth - Width of bars in pixels
*       barSpacing - Gap between bars in pixels
*       zeroAxis - Centers the y-axis around zero if true
*
*   tristate - Charts values of win (>0), lose (<0) or draw (=0)
*       posBarColor - Color of win values
*       negBarColor - Color of lose values
*       zeroBarColor - Color of draw values
*       barWidth - Width of bars in pixels
*       barSpacing - Gap between bars in pixels
*
*   Examples:
*   $('#sparkline1').sparkline(myvalues, { lineColor: '#f00', fillColor: false });
*   $('.barsparks').sparkline('html', { type:'bar', height:'40px', barWidth:5 });
*   $('#tristate').sparkline([1,1,-1,1,0,0,-1], { type:'tristate' }):
*/



(function($) {

    // Provide a cross-browser interface to a few simple drawing primitives
    $.fn.simpledraw = function(width, height) {
        if (width==undefined) width=$(this).innerWidth();
        if (height==undefined) height=$(this).innerHeight();
        if ($.browser.hasCanvas) {
            return new vcanvas_canvas(width, height, this);
        } else if ($.browser.msie) {
            return new vcanvas_vml(width, height, this);
        } else {
            return false;
        }
    };

    $.fn.sparkline = function(uservalues, options) {
        var options = $.extend({
            type : 'line',
            lineColor : '#00f',
            fillColor : '#cdf',
            width : 'auto',
            height : 'auto'
        }, options ? options : {});

        return this.each(function() {
            var values = (uservalues=='html' || uservalues==undefined) ? $(this).text().split(',') : uservalues;
            var width = options.width=='auto' ? values.length*3 : options.width;
            var height = options.height=='auto' ? $(this).innerHeight() : options.height;

            $.fn.sparkline[options.type].call(this, values, options, width, height);
        });
    };

    $.fn.sparkline.line = function(values, options, width, height) {
        var options = $.extend({
            spotColor : '#f80',
            spotRadius : 2
        }, options ? options : {});

        var max = Math.max.apply(Math, values);
        var min = Math.min.apply(Math, values);
        var range = max-min+1;
        var vl = values.length-1;

        if (range==1) { range=max*2; min=0; }

        if (vl<1) {
            this.innerHTML = '';
            return;
        }

        var target = $(this).simpledraw(width, height);
        if (target) {
            var canvas_width = target.pixel_width;
            var canvas_height = target.pixel_height;;

            if (options.spotColor) {
                canvas_width -= options.spotRadius; // leave room
            }

            var path = [ [1, target.pixel_height] ];
            for(var i=0; i<values.length; i++) {
                path.push([Math.round(i*(canvas_width/vl)+1), Math.round(canvas_height-(canvas_height*((values[i]-min)/range)))]);
            }
            if (options.fillColor) {
                path.push([canvas_width+1, canvas_height]);
                target.drawShape(path, undefined, options.fillColor);
                path.pop();
            }
            path[0] = [ 1, Math.round(canvas_height-(canvas_height*((values[0]-min)/range))) ];
            target.drawShape(path, options.lineColor);
            if (options.spotColor) {
                target.drawCircle(canvas_width,  Math.round(canvas_height-(canvas_height*((values[vl]-min)/range))), options.spotRadius, undefined, options.spotColor);
            }
        } else {
            // Remove the tag contents if sparklines aren't supported
            this.innerHTML = '';
        }
    };

    $.fn.sparkline.bar = function(values, options, width, height) {
        var options = $.extend({
            type : 'bar',
            barColor : '#00f',
            negBarColor : '#f44',
            zeroAxis : undefined,
            barWidth : 4,
            barSpacing : 1
        }, options ? options : {});

        var width = (values.length * options.barWidth) + ((values.length-1) * options.barSpacing);
        var max = Math.max.apply(Math, values);
        var min = Math.min.apply(Math, values);
        if (options.zeroAxis == undefined) options.zeroAxis = min<0;
        var range = max-min+1;

        var target = $(this).simpledraw(width, height);
        if (target) {
            var canvas_width = target.pixel_width;
            var canvas_height = target.pixel_height;
            var yzero = min<0 ? Math.round(canvas_height * (Math.abs(min)/range)) : canvas_height;

            for(var i=0; i<values.length; i++) {
                var x = i*(options.barWidth+options.barSpacing);
                var val = values[i];
                var color = (val < 0) ? options.negBarColor : options.barColor;
                if (options.zeroAxis) {
                    var height = val==0 ? 1 : Math.round(canvas_height*((Math.abs(val)/range)));
                    var y = (val < 0) ? yzero : yzero-height;
                } else {
                    var height = val==min ? 1 : Math.round(canvas_height*((val-min)/range));
                    var y = 1+(canvas_height-height);
                }
                if ($.browser.msie) // IE's bars look fuzzy without this :-/
                    target.drawRect(x, y, options.barWidth-1, height-1, color, color);
                else
                    target.drawRect(x, y, options.barWidth, height, undefined, color);
            }
        } else {
            // Remove the tag contents if sparklines aren't supported
            this.innerHTML = '';
        }
    };

    $.fn.sparkline.tristate = function(values, options, width, height) {
        var options = $.extend({
            barWidth : 4,
            barSpacing : 1,
            posBarColor: '#6f6',
            negBarColor : '#f44',
            zeroBarColor : '#999'
        }, options);

        var width = (values.length * options.barWidth) + ((values.length-1) * options.barSpacing);

        var target = $(this).simpledraw(width, height);
        if (target) {
            var canvas_width = target.pixel_width;
            var canvas_height = target.pixel_height;
            var half_height = Math.round(canvas_height/2);

            for(var i=0; i<values.length; i++) {
                var x = i*(options.barWidth+options.barSpacing);
                if (values[i] < 0) {
                    var y = half_height;
                    var height = half_height-1;
                    var color = options.negBarColor;
                } else if (values[i] > 0) {
                    var y = 1;
                    var height = half_height-1;
                    var color = options.posBarColor;
                } else {
                    var y = half_height-1;
                    var height = 2;
                    var color = options.zeroBarColor;
                }
                if ($.browser.msie) // IE's bars look fuzzy without this :-/
                    target.drawRect(x, y, options.barWidth-1, height-1, color, color);
                else
                    target.drawRect(x, y, options.barWidth, height, undefined, color);
            }
        } else {
            // Remove the tag contents if sparklines aren't supported
            this.innerHTML = '';
        }
    };


    // Setup a very simple "virtual canvas" to make drawing the few shapes we need easier
    // This is accessible as $(foo).simpledraw()

    if ($.browser.msie && !document.namespaces['v']) {
        document.namespaces.add("v", "urn:schemas-microsoft-com:vml");
        document.createStyleSheet().cssText = "v\\:*{behavior:url(#default#VML); display:inline-block; padding:0px; margin:0px;}";
    }

    if ($.browser.hasCanvas == undefined) {
        var t = document.createElement('canvas');
        $.browser.hasCanvas = t.getContext!=undefined;
    }

    var vcanvas_base = function(width, height, target) {
    };

    vcanvas_base.prototype = {
        init : function(width, height, target) {
            this.width = width;
            this.height = height;
            this.target = target;
        },

        drawShape : function(path, lineColor, fillColor) {
            alert('drawShape not implemented');
        },

        drawLine : function(x1, y1, x2, y2, lineColor) {
            return this.drawShape([ [x1,y1], [x2,y2] ], lineColor);
        },

        drawCircle : function(x, y, radius, lineColor, fillColor) {
            alert('drawCircle not implemented');
        },

        drawRect : function(x, y, width, height, lineColor, fillColor) {
            alert('drawRect not implemented');
        },

        getElement : function() {
            return this.canvas;
        },

        _insert : function(el, target) {
            $(target).html(el);
        }
    };

    var vcanvas_canvas = function(width, height, target) {
        return this.init(width, height, target);
    };

    vcanvas_canvas.prototype = $.extend(new vcanvas_base, {
        _super : vcanvas_base.prototype,

        init : function(width, height, target) {
            this._super.init(width, height, target);
            this.canvas = document.createElement('canvas');
            $(this.canvas).css({ display:'inline', width:width, height:height });
            this._insert(this.canvas, target);
            this.pixel_height = $(this.canvas).height();
            this.pixel_width = $(this.canvas).width();
            this.canvas.width = this.pixel_width;
            this.canvas.height = this.pixel_height;;
        },

        _getContext : function(lineColor, fillColor) {
            var context = this.canvas.getContext('2d');
            if (lineColor != undefined)
                context.strokeStyle = lineColor;
            context.lineWidth = 1;
            if (fillColor != undefined)
                context.fillStyle = fillColor;
            return context;
        },

        drawShape : function(path, lineColor, fillColor) {
            var context = this._getContext(lineColor, fillColor);
            context.beginPath();
            context.moveTo(path[0][0], path[0][1]-0.5);
            for(var i=1; i<path.length; i++) {
                context.lineTo(path[i][0], path[i][1]-0.5); // the 0.5 offset gives us crisp pixel-width lines
            }
            if (lineColor != undefined) {
                context.stroke();
            }
            if (fillColor != undefined) {
                context.fill();
            }
        },

        drawCircle : function(x, y, radius, lineColor, fillColor) {
            var context = this._getContext(lineColor, fillColor);
            context.beginPath();
            context.arc(x, y, radius, 0, 2*Math.PI, true);
            if (lineColor != undefined) {
                context.stroke();
            }
            if (fillColor != undefined) {
                context.fill();
            }
        },

        drawRect : function(x, y, width, height, lineColor, fillColor) {
            var context = this._getContext(lineColor, fillColor);
            if (fillColor != undefined)
                context.fillRect(x, y, width, height);
            if (lineColor != undefined)
                context.strokeRect(x, y, width, height);
        }

    });

    var vcanvas_vml = function(width, height, target) {
        return this.init(width, height, target);
    };

    vcanvas_vml.prototype = $.extend(new vcanvas_base, {
        _super : vcanvas_base.prototype,

        init : function(width, height, target) {
            this._super.init(width, height, target);
            this.canvas = document.createElement('span');
            $(this.canvas).css({ display:'inline-block', overflow:'hidden', width:width, height:height, margin:'0px', padding:'0px' });
            this._insert(this.canvas, target);
            this.pixel_height = $(this.canvas).height();
            this.pixel_width = $(this.canvas).width();
            this.canvas.width = this.pixel_width;
            this.canvas.height = this.pixel_height;;
            var groupel = '<v:group coordorigin="0 0" coordsize="'+this.pixel_width+' '+this.pixel_height+'"'
                    +' style="position:relative;top:0;left:0;width:'+this.pixel_width+'px;height='+this.pixel_height+'px;"></v:group>';
            this.canvas.insertAdjacentHTML('beforeEnd', groupel);
            this.group = $(this.canvas).children()[0];
        },

        drawShape : function(path, lineColor, fillColor) {
            var vpath = [];
            for(var i=0; i<path.length; i++) {
                vpath[i] = ''+(path[i][0]-1)+','+(path[i][1]-1);
            }
            var initial = vpath.splice(0,1);
            var stroke = lineColor == undefined ? ' stroked="false" ' : ' strokeWeight="1" strokeColor="'+lineColor+'" ';
            var fill = fillColor == undefined ? ' filled="false"' : ' fillColor="'+fillColor+'" filled="true" ';
            var closed = vpath[0] == vpath[vpath.length-1] ? 'x ' : '';
            var vel = '<v:shape coordorigin="0 0" coordsize="'+this.pixel_width+' '+this.pixel_height+'" '
                + stroke
                + fill
                +' style="position:relative;left:0px;top:0px;height:'+this.pixel_height+'px;width:'+this.pixel_width+'px;padding:0px;margin:0px;" '
                +' path="m '+initial+' l '+vpath.join(', ')+' '+closed+'e">'
                +' </v:shape>';
             this.group.insertAdjacentHTML('beforeEnd', vel);
        },

        drawCircle : function(x, y, radius, lineColor, fillColor) {
            x -= radius+1;
            y -= radius+1;
            var stroke = lineColor == undefined ? ' stroked="false" ' : ' strokeWeight="1" strokeColor="'+lineColor+'" ';
            var fill = fillColor == undefined ? ' filled="false"' : ' fillColor="'+fillColor+'" filled="true" ';
            var vel = '<v:oval '
                + stroke
                + fill
                +' style="position:absolute;top:'+y+'; left:'+x+'; width:'+(radius*2)+'; height:'+(radius*2)+'"></v:oval>';
            this.group.insertAdjacentHTML('beforeEnd', vel);

        },

        drawRect : function(x, y, width, height, lineColor, fillColor) {
            return this.drawShape( [ [x, y], [x, y+height], [x+width, y+height], [x+width, y], [x, y] ], lineColor, fillColor);
        }
    });

})(jQuery);
