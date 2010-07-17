(function() {
  var date = wesabe.lang.date;
  now = new Date();
  now = date.add(now, -now.getMilliseconds()); // shave off the milliseconds
  beginning_of_day = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  birthday = new Date(1983, 3, 19, 20, 40, 00);
  eight_this_morning = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 8);
  four_this_afternoon = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 16);
  midnight = beginning_of_day;
  noon = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12);
  noon3456 = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12, 34, 56);
  july1st = new Date(now.getFullYear(), 6, 1);
  birthdayString = '19 April 1983';
  birthday = date.parse(birthdayString);
  startOfToday = date.startOfDay(now);
  thisSunday = date.startOfWeek(now, 0);
  thisMonday = date.startOfWeek(now, 1);
  thisDefaultStartOfWeek = date.startOfWeek(now);
  the1st = date.startOfMonth(now);

  describe("wesabe.lang.date.format", {
    "'yyyy' returns the full year": function() {
      expect(date.format(birthday, "yyyy")).to(equal, "1983");
    },

    "'yy' returns the short year": function() {
      expect(date.format(birthday, "yy")).to(equal, "83");
    },

    "'M' returns the non-padded month": function() {
      expect(date.format(birthday, "M")).to(equal, "4");
    },

    "'MM' returns the padded month": function() {
      expect(date.format(birthday, "MM")).to(equal, "04");
    },

    "'MMM' returns the full month name": function() {
      expect(date.format(birthday, "MMM")).to(equal, "April");
    },

    "'d' returns the non-padded date": function() {
      expect(date.format(birthday, "d")).to(equal, "19");
    },

    "'dd' returns the padded date": function() {
      expect(date.format(birthday, "dd")).to(equal, "19");
    },

    "'E' returns the short day name": function() {
      expect(date.format(birthday, "E")).to(equal, "Tue");
    },

    "returns the long day name": function() {
      expect(date.format(birthday, "EE")).to(equal, "Tuesday");
    },

    "'H' returns 00 at midnight": function() {
      expect(date.format(midnight, "H")).to(equal, "0");
    },

    "'H' returns a non-padded 24-hour formatted hour before noon": function() {
      expect(date.format(eight_this_morning, "H")).to(equal, "8");
    },

    "'H' returns 12 at noon": function() {
      expect(date.format(noon, "H")).to(equal, "12");
    },

    "'H' returns a non-padded 24-hour formatted hour after noon": function() {
      expect(date.format(four_this_afternoon, "H")).to(equal, "16");
    },

    "'HH' returns 00 at midnight": function() {
      expect(date.format(midnight, "HH")).to(equal, "00");
    },

    "'HH' returns a padded 24-hour formatted hour before noon": function() {
      expect(date.format(eight_this_morning, "HH")).to(equal, "08");
    },

    "'HH' returns 12 at noon": function() {
      expect(date.format(noon, "HH")).to(equal, "12");
    },

    "'HH' returns a padded 24-hour formatted hour after noon": function() {
      expect(date.format(four_this_afternoon, "HH")).to(equal, "16");
    },

    "'h' returns 12 at midnight": function() {
      expect(date.format(midnight, "h")).to(equal, "12");
    },

    "'h' returns a non-padded 12-hour formatted hour before noon": function() {
      expect(date.format(eight_this_morning, "h")).to(equal, "8");
    },

    "'h' returns 12 at noon": function() {
      expect(date.format(noon, "h")).to(equal, "12");
    },

    "'h' returns a non-padded 12-hour formatted hour after noon": function() {
      expect(date.format(four_this_afternoon, "h")).to(equal, "4");
    },

    "'hh' returns 12 at midnight": function() {
      expect(date.format(midnight, "hh")).to(equal, "12");
    },

    "'hh' returns a padded 12-hour formatted hour before noon": function() {
      expect(date.format(eight_this_morning, "hh")).to(equal, "08");
    },

    "'hh' returns 12 at noon": function() {
      expect(date.format(noon, "hh")).to(equal, "12");
    },

    "'hh' returns a padded 12-hour formatted hour after noon": function() {
      expect(date.format(four_this_afternoon, "hh")).to(equal, "04");
    },

    "'K' returns 0 at midnight": function() {
      expect(date.format(midnight, "K")).to(equal, "0");
    },

    "'K' returns a non-padded 12-hour formatted hour before noon": function() {
      expect(date.format(eight_this_morning, "K")).to(equal, "8");
    },

    "'K' returns a non-padded 12-hour formatted hour after noon": function() {
      expect(date.format(four_this_afternoon, "K")).to(equal, "4");
    },

    "'K' returns a non-padded zero-based hour at noon": function() {
      expect(date.format(noon, "K")).to(equal, "0");
    },

    "'a' returns AM at midnight": function() {
      expect(date.format(midnight, "a")).to(equal, "AM");
    },

    "'a' returns AM before noon": function() {
      expect(date.format(eight_this_morning, "a")).to(equal, "AM");
    },

    "'a' returns PM after noon": function() {
      expect(date.format(four_this_afternoon, "a")).to(equal, "PM");
    },

    "'a' returns PM at noon": function() {
      expect(date.format(noon, "a")).to(equal, "PM");
    },

    "'m' returns a non-padded minute": function() {
      expect(date.format(noon3456, "m")).to(equal, "34");
    },

    "'mm' returns a padded minute": function() {
      expect(date.format(noon3456, "mm")).to(equal, "34");
    },

    "'s' returns a non-padded second": function() {
      expect(date.format(noon3456, "s")).to(equal, "56");
    },

    "'ss' returns a padded second": function() {
      expect(date.format(noon3456, "ss")).to(equal, "56");
    },

    "replaces all the tokens in place": function() {
      expect(date.format(noon3456, "ha")).to(equal, "12PM");
    },

    "preserves non-token strings": function() {
      expect(date.format(noon3456, "h:mm:ss")).to(equal, "12:34:56");
    }
  });

  describe("wesabe.lang.date.add", {
    "adds a number of milliseconds to a date": function() {
      expect(date.add(now, 60*1000).getMinutes()).to(equal, now.getMinutes() + 1);
    }
  });

  describe("wesabe.lang.date.addDays", {
    "doesn't change the date when given 0": function() {
      expect(date.addDays(birthday, 0)).to(equal, birthday);
    },

    "with a number less than the number required to move to the next month adds the number to the existing date": function() {
      expect(date.addDays(birthday, 1).getDate()).to(equal, birthday.getDate() + 1);
    },

    "with a number greater than the number required to move to the next month adds the number to the existing date modulo the number of days in that month": function() {
      expect(date.addDays(birthday, 15).getDate()).to(equal, 4);
    },

    "with a number greater than the number required to move to the next month adds 1 to the month": function() {
      expect(date.addDays(birthday, 15).getMonth()).to(equal, birthday.getMonth() + 1);
    }
  });

  describe("wesabe.lang.date.addWeeks", {
    "adds a number of weeks to a date": function() {
      expect(date.addWeeks(birthday, 1).getDate()).to(equal, 26);
      expect(date.addWeeks(birthday, 2).getDate()).to(equal, 3);
    }
  });

  describe("wesabe.lang.date.addMonths", {
    "doesn't change the date given 0": function() {
      expect(date.addMonths(birthday, 0)).to(equal, birthday);
    },

    "with a number less than the number required to move to next year adds the number to the existing month": function() {
      expect(date.addMonths(birthday, 1).getMonth()).to(equal, birthday.getMonth() + 1);
    },

    "with a number greater than the number required to move to the next year adds a number of months to a date": function() {
      expect(date.addMonths(birthday, 11).getMonth()).to(equal, 2);  // March '84
    }
  });

  describe("wesabe.lang.date.addYears", {
    "doesn't change the date given 0": function() {
      expect(date.addYears(birthday, 0)).to(equal, birthday);
    },

    "with a positive number adds the number to the existing year": function() {
      expect(date.addYears(birthday, 1).getFullYear()).to(equal, birthday.getFullYear() + 1);
    },

    "with a negative number subtracts the number of years from a date": function() {
      expect(date.addYears(birthday, -2).getFullYear()).to(equal, birthday.getFullYear() - 2);
    }
  });

  describe("wesabe.lang.date.parse", {
    "given a string generated by Date#toString equals the date the string was generated from": function() {
      expect(date.parse(now.toString())).to(equal, now);
    },

    "given a xmlschema-formatted date in UTC parses it and adjusts the timezone": function() {
      xmlbirthday = "1983-04-19T20:40:00Z";
      xmlschema = date.format(now, "yyyy-MM-ddTHH:mm:ssZ");
      tzOffset = -now.getTimezoneOffset()*date.MINUTES;

      expect(date.parse(xmlbirthday))
        .to(equal, date.add(birthday, tzOffset));
      expect(date.parse(xmlschema))
        .to(equal, date.add(now, tzOffset));
    },

    "given a xmlschema-formatted date not in UTC parses it and adjusts the timezone": function() {
      xmlbirthday = "1983-04-19T20:40:00-0700";
      xmlschema = date.format(now, "yyyy-MM-ddTHH:mm:ss-0700");
      tzOffset = 7*date.HOURS - now.getTimezoneOffset()*date.MINUTES;

      expect(date.parse(xmlbirthday))
        .to(equal, date.add(birthday, tzOffset));
      expect(date.parse(xmlschema))
        .to(equal, date.add(now, tzOffset));
    },

    "given a compacted xmlschema-formatted date not in UTC parses it and adjusts the timezone": function() {
      compactedxmlschema = "20090507T141854-0700";
      expect(date.parse(compactedxmlschema))
        .to(equal, date.parse("20090507T211854Z"));
    },

    "parses a date formatted by #toParam correctly": function() {
      expect(date.parse(date.toParam(now))).to(equal, beginning_of_day);
    },

    "throws an exception given an invalid date": function() {
      expect(function(){ date.parse('fooos') }).to(throw_error);
    },

    "returns null given a null date": function() {
      expect(date.parse(null)).to(be_null);
    }
  });

  describe("wesabe.lang.date.friendlyFormat", {
    "omits the year given a date in this year": function() {
      expect(date.friendlyFormat(july1st)).to(match, (/July 1st$/));
    },

    "includes the year given a date in another year": function() {
      expect(date.friendlyFormat(birthday)).to(equal, "Tuesday, April 19th, 1983");
    },

    "parses valid date strings": function() {
      expect(date.friendlyFormat("4/19/1983")).to(equal, "Tuesday, April 19th, 1983");
    },

    "returns an empty string given invalid dates": function() {
      expect(date.friendlyFormat("foobar")).to(equal, "");
    },

    "returns an empty string given null": function() {
      expect(date.friendlyFormat(null)).to(equal, "");
    }
  });

  describe("wesabe.lang.date.shortFriendlyFormat", {
    "omits the year given a date in this year": function() {
      expect(date.shortFriendlyFormat(july1st)).to(match, (/July 1$/));
    },

    "includes the year given a date in another year": function() {
      expect(date.shortFriendlyFormat(birthday)).to(equal, "April 19, 1983");
    },

    "parses valid date strings": function() {
      expect(date.shortFriendlyFormat("4/19/1983")).to(equal, "April 19, 1983");
    },

    "returns an empty string given invalid dates": function() {
      expect(date.shortFriendlyFormat("foobar")).to(equal, "");
    },

    "returns an empty string given null": function() {
      expect(date.shortFriendlyFormat(null)).to(equal, "");
    }
  });

  describe("wesabe.lang.date.distanceOfTimeInWords", {
    "shows 'less than a minute ago' when the delta is less than a minute": function() {
      aMinuteFromNow = date.add(now, 30 * date.SECONDS);

      expect(date.distanceOfTimeInWords(now, aMinuteFromNow))
        .to(equal, "less than a minute ago");
    },

    "shows 'about a minute ago' when the delta is less than 120 seconds": function() {
      ninetySecondsFromNow = date.add(now, 90 * date.SECONDS);

      expect(date.distanceOfTimeInWords(now, ninetySecondsFromNow))
        .to(equal, "about a minute ago");
    },

    "shows 'N minutes ago' when the delta is less than an hour": function() {
      thirtyMinutesFromNow = date.add(now, 30 * date.MINUTES);

      expect(date.distanceOfTimeInWords(now, thirtyMinutesFromNow))
        .to(equal, "30 minutes ago");
    },

    "shows 'about an hour ago' when the delta is less than 120 minutes": function() {
      ninetyMinutesFromNow = date.add(now, 90 * date.MINUTES);

      expect(date.distanceOfTimeInWords(now, ninetyMinutesFromNow))
        .to(equal, "about an hour ago");
    },

    "shows 'about N hours ago' when the delta is less than a day": function() {
      nineHoursFromNow = date.add(now, 9 * date.HOURS);

      expect(date.distanceOfTimeInWords(now, nineHoursFromNow))
        .to(equal, "about 9 hours ago");
    },

    "shows '1 day ago' when the delta is less than 48 hours": function() {
      thirtySixHoursFromNow = date.add(now, 36 * date.HOURS);

      expect(date.distanceOfTimeInWords(now, thirtySixHoursFromNow))
        .to(equal, "1 day ago");
    },

    "shows 'Month Date, Year' when the delta is more than 5 days": function() {
      weekAfterBirthday = date.add(birthday, 7 * date.DAYS);

      expect(date.distanceOfTimeInWords(birthday, weekAfterBirthday))
        .to(equal, "April 19, 1983");
    },

    "when the fromTime or toTime are strings should convert them to Dates": function() {
      stringFromDate = "1983-04-19T20:40:00Z";
      stringToDate = "1983-04-20T20:40:00Z";

      expect(date.distanceOfTimeInWords(stringFromDate, stringToDate))
        .to(equal, "1 day ago");
    }
  });

  describe("wesabe.lang.date.timeAgoInWords", {
    "calls distanceOfTimeInWords with the current time": function() {
      yesterday = date.add(now, -1 * date.DAY);

      expect(date.timeAgoInWords(yesterday)).to(equal, "1 day ago");
    }
  });

  describe("wesabe.lang.date.toParam", {
    "formats the date as yyyyMMdd": function() {
      expect(date.toParam(birthday)).to(equal, "19830419");
    },

    "parses a date string, if necessary": function() {
      expect(date.toParam(birthdayString)).to(equal, "19830419");
    },

    "returns empty string if an invalid date is given": function() {
      expect(date.toParam('narf!')).to(be_empty);
    }
  });

  describe("wesabe.lang.date.startOfDay", {
    "always has the same year as the argument": function() {
      expect(startOfToday.getFullYear()).to(equal, now.getFullYear());
    },

    "always has the same month as the argument": function() {
      expect(startOfToday.getMonth()).to(equal, now.getMonth());
    },

    "always has the same date as the argument": function() {
      expect(startOfToday.getDate()).to(equal, now.getDate());
    }
  });

  describe("wesabe.lang.date.startOfWeek", {
    "defaults to Sunday as the first day of the week": function() {
      expect(thisDefaultStartOfWeek).to(equal, thisSunday);
    },

    "has day of week equal to the 2nd (optional) argument": function() {
      expect(thisSunday.getDay()).to(equal, 0);
      expect(thisMonday.getDay()).to(equal, 1);
    }
  });

  describe("wesabe.lang.date.startOfMonth", {
    "always has the same month as the argument": function() {
      expect(the1st.getMonth()).to(equal, now.getMonth());
    },

    "always is on the 1st": function() {
      expect(the1st.getDate()).to(equal, 1);
    }
  });

  describe("wesabe.lang.date.startOfQuarter", {
    before: function() {
      dates = {
        q1: date.parse("1/19/1971 11:28:00"),
        q2: date.parse("6/2/2009 16:34:22"),
        q3: date.parse("9/22/2008 19:01:00"),
        q4: date.parse("12/31/2009 23:59:59")
      };
    },

    "first quarter starts on January 1 of the same year as argument": function() {
      expect(date.startOfQuarter(dates.q1)).to(equal, date.parse("1/1/1971 00:00:00"));
    },

    "second quarter starts on April 1 of the same year as argument": function() {
      expect(date.startOfQuarter(dates.q2)).to(equal, date.parse("4/1/2009 00:00:00"));
    },

    "third quarter starts on July 1 of the same year as argument": function() {
      expect(date.startOfQuarter(dates.q3)).to(equal, date.parse("7/1/2008 00:00:00"));
    },

    "fourth quarter starts on October 1 of the same year as argument": function() {
      expect(date.startOfQuarter(dates.q4)).to(equal, date.parse("10/1/2009 00:00:00"));
    }
  });

  describe("wesabe.lang.date.endOfQuarter", {
    before: function() {
      dates = {
        q1: date.parse("1/19/1971 11:28:00"),
        q2: date.parse("6/2/2009 16:34:22"),
        q3: date.parse("9/22/2008 19:01:00"),
        q4: date.parse("12/31/2009 23:59:59")
      };
    },

    "first quarter ends on March 31 of the same year as argument": function() {
      expect(date.endOfQuarter(dates.q1)).to(equal, date.parse("3/31/1971 00:00:00"));
    },

    "second quarter end on June 30 of the same year as argument": function() {
      expect(date.endOfQuarter(dates.q2)).to(equal, date.parse("6/30/2009 00:00:00"));
    },

    "third quarter end on September 30 of the same year as argument": function() {
      expect(date.endOfQuarter(dates.q3)).to(equal, date.parse("9/30/2008 00:00:00"));
    },

    "fourth quarter ends on December 31 of the same year as argument": function() {
      expect(date.endOfQuarter(dates.q4)).to(equal, date.parse("12/31/2009 00:00:00"));
    }
  });

  describe("wesabe.lang.date.startOfYear", {
    before: function() {
      ballDrop = date.parse("12/31/2008 23:59:59");
    },

    "always has the same year as the argument": function() {
      expect(date.startOfYear(now).getFullYear()).to(equal, now.getFullYear());
      expect(date.startOfYear(ballDrop).getFullYear()).to(equal, ballDrop.getFullYear());
    },

    "always is on January 1st": function() {
      jQuery.each([now, ballDrop], function(i, d) {
        ds = date.startOfYear(d);
        expect(ds.getMonth()).to(equal, 0); // months are 0-based on JS
        expect(ds.getDate()).to(equal, 1);
      });
    }
  });

  describe("wesabe.lang.date.endOfYear", {
    "always has the same year as the argument": function() {
      expect(date.endOfYear(now).getFullYear()).to(equal, now.getFullYear());
      expect(date.endOfYear(birthday).getFullYear()).to(equal, birthday.getFullYear());
    },

    "always is on December 31st": function() {
      jQuery.each([now, birthday], function(i, d) {
        ds = date.endOfYear(d);
        expect(ds.getMonth()).to(equal, 11); // months are 0-based on JS
        expect(ds.getDate()).to(equal, 31);
      });
    }
  });

  describe("wesabe.lang.date.startOf", {
    "given 'day' uses startOfDay": function() {
      expect(date.startOf('day', now)).to(equal, date.startOfDay(now));
    },

    "given 'week' uses startOfWeek": function() {
      expect(date.startOf('week', now)).to(equal, date.startOfWeek(now));
    },

    "given 'month' uses startOfMonth": function() {
      expect(date.startOf('month', now)).to(equal, date.startOfMonth(now));
    },

    "given 'year' uses startOfYear": function() {
      expect(date.startOf('year', now)).to(equal, date.startOfYear(now));
    },

    "given an invalid unit throws an exception": function() {
      expect(function(){ date.startOf('foo', now) })
        .to(throw_error, /^foo is not a valid unit - use day, week, month or year/);
    }
  });

  describe("wesabe.lang.date.doWithUnit", {
    "throws an exception given an invalid action": function() {
      // expect(function(){ date.doWithUnit('foogle', 'week', new Date(), 1) })
      //   .to(throw_error, /^No function named one of (foogleWeek, foogleWeeks) could be found in wesabe.lang.date/);
    },

    "can call singular unit functions": function() {
      expect(date.doWithUnit('startOf', 'day', now)).to(equal, date.startOfDay(now));
    },

    "can call plural unit functions": function() {
      expect(date.doWithUnit('add', 'day', now, 10)).to(equal, date.addDays(now, 10));
    },

    "can recognize units case-insensitive": function() {
      expect(date.doWithUnit('add', 'YeAr', now, 2)).to(equal, date.addYears(now, 2));
    }
  });

  describe("wesabe.lang.date.equals", {
    before: function() {
      date1 = new Date(1971, 0, 19, 11, 23, 00);
      date2 = new Date(1971, 0, 19, 11, 23, 00);
      date3 = new Date(1971, 0, 19, 11, 23, 01);
    },

    "returns true if the dates are equal": function() {
      expect(date.equals(date1, date2)).to(equal, true);
    },

    "returns false if the dates are not equal": function() {
      expect(date.equals(date1, date3)).to(equal, false);
    }
  });
})();
