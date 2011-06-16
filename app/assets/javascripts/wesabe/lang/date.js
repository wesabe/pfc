wesabe.provide('lang.date');

wesabe.lang.date = {
  MONTH_NAMES: [
    'January','February','March','April','May','June','July',
    'August','September','October','November','December',
    'Jan','Feb','Mar','Apr','May','Jun','Jul',
    'Aug','Sep','Oct','Nov','Dec'
  ],

  DAY_NAMES: [
    'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday',
    'Sun','Mon','Tue','Wed','Thu','Fri','Sat'
  ],

  LZ: function(x) {
    return (x<0||x>9?"":"0")+x;
  },

  SECOND: 1000,
  SECONDS: 1000,

  parse: function(string) {
    if (!string)
      return null;

    var p = function(s) { return parseInt(s, 10); };

    var idate = Date.parse(string);
    if (isNaN(idate)) {
      var m;

      // xml schema format yyyy-MM-ddTHH:mm:ssZ or yyyy-MM-ddTHH:mm:ss+-hhmm
      m = string.match(/^(\d{4})-?(\d{2})-?(\d{2})T(\d{2}):?(\d{2}):?(\d{2})(?:Z|([+-])(\d{2})(\d{2}))$/);
      if (m) {
        var year = p(m[1]), month = p(m[2]) - 1, day = p(m[3]);
        var hour = p(m[4]), minute = p(m[5]), second = p(m[6]);
        var utcResult, result = new Date(year, month, day, hour, minute, second);
        if (!m[7]) {
          utcResult = result;
        } else {
          var tzsign  = (m[7] == '+') ? 1 : -1;
          var tzhours = p(m[8]);
          var tzmins  = p(m[9]);
          var tzoffset = -tzsign * (tzhours * this.HOURS + tzmins * this.MINUTES);
          utcResult = this.add(result, tzoffset);
        }
        result = this.add(utcResult, -new Date().getTimezoneOffset()*this.MINUTES);
        return result;
      }

      // url parameter format
      m = string.match(/^(\d{4})-?(\d{2})-?(\d{2})$/);
      if (m) {
        var year = p(m[1]), month = p(m[2]) - 1, day = p(m[3]);
        return new Date(year, month, day);
      }

      wesabe.warn('unable to parse date: ', string);
      return null;
    }
    return new Date(idate);
  },

  //
  // Date Math
  //

  add: function(date, duration) {
    return new Date(date.getTime() + duration);
  },

  addDays: function(date, days) {
    return YAHOO.widget.DateMath.add(date, YAHOO.widget.DateMath.DAY, days);
  },

  addWeeks: function(date, weeks) {
    return YAHOO.widget.DateMath.add(date, YAHOO.widget.DateMath.WEEK, weeks);
  },

  addMonths: function(date, months) {
    return YAHOO.widget.DateMath.add(date, YAHOO.widget.DateMath.MONTH, months);
  },

  addYears: function(date, years) {
    return YAHOO.widget.DateMath.add(date, YAHOO.widget.DateMath.YEAR, years);
  },

  startOfYear: function(date) {
    return YAHOO.widget.DateMath.getJan1(date.getFullYear());
  },

  endOfYear: function(date) {
    return new Date(date.getFullYear(), 11, 31);
  },

  startOfQuarter: function(date) {
    return new Date(date.getFullYear(), Math.floor(date.getMonth() / 3) * 3, 1);
  },

  endOfQuarter: function(date) {
    return wesabe.lang.date.endOfMonth(
      new Date(date.getFullYear(), (Math.floor(date.getMonth() / 3) * 3) + 2, 1));
  },

  startOfMonth: function(date) {
    return YAHOO.widget.DateMath.findMonthStart(date);
  },

  endOfMonth: function(date) {
    return YAHOO.widget.DateMath.findMonthEnd(date);
  },

  startOfWeek: function(date, firstDay) {
    return YAHOO.widget.DateMath.getFirstDayOfWeek(date, firstDay);
  },

  startOfDay: function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  },

  startOf: function(unit, date) {
    return wesabe.lang.date.doWithUnit('startOf', unit, date);
  },

  before: function(date, compareTo) {
    return YAHOO.widget.DateMath.before(date, compareTo);
  },

  after: function(date, compareTo) {
    return YAHOO.widget.DateMath.after(date, compareTo);
  },

  between: function(date, dateBegin, dateEnd) {
    return YAHOO.widget.DateMath.between(date, dateBegin, dateEnd);
  },

  overlap: function(range1, range2) {
    return wesabe.lang.date.between(range1.start, range2.start, range2.end) ||
           wesabe.lang.date.between(range1.end,   range2.start, range2.end);
  },

  equals: function(date1, date2) {
    return date1.valueOf() == date2.valueOf();
  },

  doWithUnit: function() {
    var args = jQuery.makeArray(arguments),
        name = args.shift(),
        unit = args.shift();

    u = /^day/i.test(unit)    ?  'Day'   :
        /^month/i.test(unit)  ?  'Month' :
        /^year/i.test(unit)   ?  'Year'  :
        /^week/i.test(unit)   ?  'Week'  :
        null;
    if (!u) throw new Error(unit+" is not a valid unit - use day, week, month or year");

    var possibleFunctions = [name+u, name+u+'s'];

    var fn;
    for (var i = 0; i < possibleFunctions.length; i++) {
      if (fn = wesabe.lang.date[possibleFunctions[i]]) break;
    }
    if (fn) return fn.apply(wesabe.lang.date, args);
    else throw new Error("No function named one of ("+possibleFunctions.join(', ')+") could be found in wesabe.lang.date");
  },

  //
  // Date Formatting
  //

  format: function(date, format) {
    var LZ = wesabe.lang.date.LZ;

    format = format + "";
    var result = "";
    var i_format = 0;
    var c = "";
    var token = "";
    var y = date.getYear()+"";
    var M = date.getMonth()+1;
    var d = date.getDate();
    var E = date.getDay();
    var H = date.getHours();
    var m = date.getMinutes();
    var s = date.getSeconds();
    var yyyy,yy,MMM,MM,dd,hh,h,mm,ss,ampm,HH,H,KK,K,kk,k;
    // Convert real date parts into formatted versions
    var value = new Object();
    if (y.length < 4) {
      y=""+(y-0+1900);
    }
    value["y"] = ""+y;
    value["yyyy"] = y;
    value["yy"] = y.substring(2,4);
    value["M"] = M;
    value["MM"] = LZ(M);
    value["MMM"] = wesabe.lang.date.MONTH_NAMES[M-1];
    value["NNN"] = wesabe.lang.date.MONTH_NAMES[M+11];
    value["d"] = d;
    value["dd"] = LZ(d);
    value["E"] = wesabe.lang.date.DAY_NAMES[E+7];
    value["EE"] = wesabe.lang.date.DAY_NAMES[E];
    value["H"] = H;
    value["HH"] = LZ(H);
    if (H == 0) {
      value["h"] = 12;
    } else if (H>12) {
      value["h"] = H-12;
    } else {
      value["h"] = H;
    }
    value["hh"] = LZ(value["h"]);
    if (H>11) {
      value["K"] = H-12;
    } else {
      value["K"] = H;
    }
    value["k"] = H+1;
    value["KK"] = LZ(value["K"]);
    value["kk"] = LZ(value["k"]);
    if (H > 11) {
      value["a"] = "PM";
    } else {
      value["a"] = "AM";
    }
    value["m"] = m;
    value["mm"] = LZ(m);
    value["s"] = s;
    value["ss"] = LZ(s);
    while (i_format < format.length) {
      c = format.charAt(i_format);
      token = "";
      while ((format.charAt(i_format) == c) && (i_format < format.length)) {
        token += format.charAt(i_format++);
      }
      if (value[token] != null) {
        result = result + value[token];
      } else {
        result = result + token;
      }
    }
    return result;
  },

  toParam: function(date) {
    if (typeof date == 'string') date = wesabe.lang.date.parse(date);
    if (!date) return '';
    return wesabe.lang.date.format(date, "yyyyMMdd");
  },

  // Tuesday, July 1st or Tuesday, July 1st, 2008
  friendlyFormat: function(date) {
    if (typeof date == 'string') date = wesabe.lang.date.parse(date);
    if (!date) return '';
    var string = '';
    string += wesabe.lang.date.format(date, 'EE, MMM ');      // "Tuesday, July"
    string += wesabe.lang.number.ordinalize(date.getDate());  // "1st"
    if (date.getYear() != new Date().getYear())
      string += wesabe.lang.date.format(date, ', yyyy');       // ", 2008"
    return string;
  },

  // July 1 or July 1, 2008
  shortFriendlyFormat: function(date) {
    if (typeof date == 'string') date = wesabe.lang.date.parse(date);
    if (!date) return '';
    var string = '';
    string += wesabe.lang.date.format(date, 'MMM d');      // "July 1"
    if (date.getYear() != new Date().getYear())
      string += wesabe.lang.date.format(date, ', yyyy');       // ", 2008"
    return string;
  },

  timeAgoInWords: function(targetDate, includeTime) {
    return wesabe.lang.date.distanceOfTimeInWords(targetDate, new Date(), includeTime);
  },

  distanceOfTimeInWords: function(fromTime, toTime, includeTime) {
    if (typeof fromTime == 'string') fromTime = wesabe.lang.date.parse(fromTime);
    if (typeof toTime == 'string') toTime = wesabe.lang.date.parse(toTime);
    var delta = parseInt((toTime.getTime()-fromTime.getTime())/1000);
    if (delta < 60) {
      return'less than a minute ago';
    } else if (delta < 120) {
      return'about a minute ago';
    } else if (delta < (45*60)) {
      return (parseInt(delta/60)).toString()+' minutes ago';
    } else if (delta < (120*60)) {
      return'about an hour ago';
    } else if (delta < (24*60*60)) {
      return'about '+(parseInt(delta/3600)).toString()+' hours ago';
    } else if (delta < (48*60*60)) {
      return'1 day ago';
    } else {
      var days = (parseInt(delta/86400)).toString();
      if (days > 5) {
        var fmt='%B %d, %Y';
        if(includeTime) fmt += ' %I:%M %p';
        return wesabe.lang.date.format(fromTime, 'MMM dd, yyyy');
      } else {
        return days+" days ago";
      }
    }
  },

  relatize: function(context) {
    context = context || document;
    jQuery(context).find("span.relatize").each(function() {
      var el = jQuery(this);
      var date = wesabe.lang.date.parse(el.text());
      el.html(wesabe.lang.date.timeAgoInWords(date));
      el.attr("title", date.toString());
    });
  }
};

wesabe.lang.date.MINUTE = wesabe.lang.date.MINUTES = 60 * wesabe.lang.date.SECONDS;
wesabe.lang.date.HOUR   = wesabe.lang.date.HOURS   = 60 * wesabe.lang.date.MINUTES;
wesabe.lang.date.DAY    = wesabe.lang.date.DAYS    = 24 * wesabe.lang.date.HOURS;

jQuery(function(){ wesabe.lang.date.relatize(); });
