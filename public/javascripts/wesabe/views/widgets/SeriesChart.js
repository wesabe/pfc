wesabe.$class('views.widgets.SeriesChart', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    chartInset: null,

    xValueFormatter: function() {
      return this._xValueFormatter || {
        format: function(value){ return ''+value; }
      };
    },

    setXValueFormatter: function(xValueFormatter) {
      this._xValueFormatter = xValueFormatter;
    },

    yValueFormatter: function() {
      return this._yValueFormatter || {
        format: function(value){ return ''+value; }
      };
    },

    setYValueFormatter: function(yValueFormatter) {
      this._yValueFormatter = yValueFormatter;
    },

    /**
     * @private
     */
    _canvas: null,
    /**
     * @private
     */
    _handle: null,
    /**
     * Caches the maximum Y-value we've seen for scaling purposes.
     *
     * @private
     */
    _maxYValue: 0,
    /**
     * Stores info about the series we're drawing.
     *
     * @private
     */
    _series: null,
    /**
     * @private
     */
    _scrollableElements: null,
    /**
     * @private
     */
    _xOffset: 0,

    init: function(element) {
      $super.init.call(this, element || $('<div></div>'));

      var self = this;
      this.get('element').mousewheel(function(){ self.onMousewheel.apply(self, arguments) });

      this._series = [];
    },

    addSeries: function(series) {
      this._series.push(series);

      for (var i = 0; i < this._series.length; i++) {
        var data = this._series[i].data;

        for (var j = 0; j < data.length; j++) {
          if (data[j].y > this._maxYValue)
            this._maxYValue = data[j].y;
        }
      }

      this.setNeedsRedraw(true);
    },

    clearSeries: function() {
      this._series = [];
      this._maxYValue = 0;
      this.setNeedsRedraw(true);
    },

    setChartInset: function(chartInset) {
      this.chartInset = chartInset;
      this.setNeedsRedraw(true);
    },

    redraw: function() {
      $super.redraw.call(this);

      if (!this._canvas)
        this._canvas = Raphael(this.get('element').get(0), this.get('contentWidth'), this.get('contentHeight'));

      this._canvas.clear();
      this._scrollableElements = [];

      if (this._series.length == 0)
        return;

      this._drawGrid();
      this._drawSeriesData();
      this._drawLabels();

      var self = this;
      this._canvas
        .rect(0, 0, this.get('contentWidth'), this.get('contentHeight'))
          .attr('stroke-width', 0).attr('fill', 'rgba(0,0,0,0)')
          .drag(function(){ self.onDragMove.apply(self, arguments) },
                function(){ self.onDragStart.apply(self, arguments); },
                function(){ self.onDragEnd.apply(self, arguments); });
    },

    onMousewheel: function(event) {
      if (event.wheelDeltaX)
        this.set('xOffset', this.get('xOffset')+event.wheelDeltaX);
    },

    onDragMove: function(dx, dy) {
      this.set('xOffset', this._dragOffset+dx);
    },

    onDragStart: function() {
      this._dragOffset = this.get('xOffset');
    },

    onDragEnd: function() {
      this._dragOffset = 0;
    },

    setXOffset: function(xOffset) {
      var oldOffset = this._xOffset,
          newOffset = xOffset;

      for (var i = 0; i < this._scrollableElements.length; i++) {
        var element = this._scrollableElements[i];

        if (!('_originalX' in element))
          element._originalX = element.attr('x')-oldOffset;

        element.attr('x', element._originalX+newOffset);
      }

      this._xOffset = newOffset;
    },

    /**
     * @private
     */
    _drawLabels: function() {
      var gridLines = 6,
          canvas = this._canvas,
          chartRect = this.get('chartRect'),
          height = chartRect.size.height,
          x0 = 45,
          x1 = this.get('contentWidth')-45;

      for (var i = gridLines-1; i > 0; i--) {
        var y = (i-1)*(height/(gridLines-1)),
            value = (gridLines-i)/(gridLines-1) * this._maxYValue,
            textValue = this.get('yValueFormatter').format(value);

        canvas.text(x0, y+8, textValue).attr('text-anchor', 'end');
        canvas.text(x1, y+8, textValue).attr('text-anchor', 'start');
      }

      if (this._series.length == 0)
        return;

      var chartBottom = chartRect.origin.y+chartRect.size.height,
          y = chartBottom+7,
          barWidth = 20,
          xSpacing = (barWidth / 2) * (this._series.length + 2) + 2,
          data = this._series[0].data;

      for (var i = 0; i < data.length; i++) {
        var datum = data[i],
            x0 = chartRect.origin.x+(i * xSpacing),
            textValue = this.get('xValueFormatter').format(datum.x, i, data.length);

        var text = canvas.text(0, y, textValue),
            textBox = text.getBBox();

        this._scrollableElements.push(text.attr({
          x: x0+(((this._series.length+1)*barWidth/2) - textBox.width) / 2,
          y: y + textBox.height/2
        }));
      }
    },

    /**
     * NOTE: all the 0.5s in this method are to make sure we actually
     * draw single-pixel lines, since SVG drawing for (x, y) is actually
     * done at (x+0.5, y+0.5).
     *
     * @private
     */
    _drawGrid: function() {
      var gridLines = 6,
          canvas = this._canvas,
          height = this.get('chartRect').size.height,
          x0 = 0,
          x1 = this.get('contentWidth');

      for (var i = 0; i < gridLines-1; i++) {
        var y = Math.round(i*(height/(gridLines-1)))+0.5;
        canvas.path('M'+x0+' '+y+' L'+x1+' '+y).attr({
          stroke: 'rgb(229,229,229)',
          'stroke-width': 0.5
        });
      }

      // draw the bottom one darker
      canvas.path('M'+x0+' '+(height+0.5)+' L'+x1+' '+(height+0.5)).attr({
        stroke: 'rgb(200,200,200)',
        'stroke-width': 0.5
      });
    },

    /**
     * @private
     */
    _drawSeriesData: function() {
      var barWidth = 20,
          xSpacing = (barWidth / 2) * (this._series.length + 2) + 2;

      for (var i = this._series.length; i--; ) {
        var series = this._series[i],
            data = series.data,
            color = series.color;

        for (var j = 0; j < data.length; j++) {
          var datum = data[j];
          this._scrollableElements.push(
            this._addBar(this._xOffset + j*xSpacing + i*barWidth/2 /* half overlap */, datum.y, color));
        }
      }
    },

    chartRect: function() {
      var inset = this.get('chartInset');

      return {
        origin: {
          x: inset.left,
          y: inset.top
        },
        size: {
          width: this.get('contentWidth') - inset.left - inset.right,
          height: this.get('contentHeight') - inset.top - inset.bottom
        }
      };
    },

    /**
     * @private
     */
    _addBar: function(offset, value, color) {
      var chartRect = this.get('chartRect'),
          width = 20.0,
          x = chartRect.origin.x + offset - width/2.0,
          height = chartRect.size.height * (value / this._maxYValue),
          y = chartRect.origin.y + chartRect.size.height - height;

      var rect = this._canvas.rect(x, y+height, width, 0);
      rect.attr({fill: color, stroke: 'none'});
      rect.animate({height: height, y: y}, 250);
      return rect;
    }
  });
});
