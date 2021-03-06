/******************************************************************************
License:
Copyright (c) 2007 Jarrett Billingsley

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it freely,
subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software in a
	product, an acknowledgment in the product documentation would be
	appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not
	be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source distribution.
******************************************************************************/

module minid.timelib;

import minid.types;
import minid.utils;

import tango.text.locale.Convert;
import tango.text.locale.Core;
import tango.time.Clock;
import tango.time.Time;
import tango.time.StopWatch;
import tango.time.WallClock;
import tango.time.chrono.Gregorian;

version(Windows)
{
	private extern(Windows) int QueryPerformanceFrequency(ulong* frequency);
	private extern(Windows) int QueryPerformanceCounter(ulong* count);
}
else version(Posix)
{
	import tango.stdc.posix.sys.time;
}
else
	static assert(false, "No valid platform defined");

final class TimeLib
{
static:
	private MDValue YearString;
	private MDValue MonthString;
	private MDValue DayString;
	private MDValue HourString;
	private MDValue MinString;
	private MDValue SecString;
	version(Windows) ulong performanceFreq;

	static this()
	{
		YearString = new MDString("year"d);
		MonthString = new MDString("month"d);
		DayString = new MDString("day"d);
		HourString = new MDString("hour"d);
		MinString = new MDString("min"d);
		SecString = new MDString("sec"d);

		version(Windows)
		{
			if(!QueryPerformanceFrequency(&performanceFreq))
				performanceFreq = 0x7fffffffffffffffL;
		}
	}

	public void init(MDContext context)
	{
		context.setModuleLoader("time", context.newClosure(function int(MDState s, uint numParams)
		{
			auto perfCounterClass = new MDPerfCounterClass(s.context.globals.get!(MDObject)("Object"d));

			auto lib = s.getParam!(MDNamespace)(1);

			lib.addList
			(
				"PerfCounter"d,  perfCounterClass,
				"microTime"d,    new MDClosure(lib, &microTime,  "times.microTime"),
				"dateString"d,   new MDClosure(lib, &dateString, "time.dateString"),
				"dateTime"d,     new MDClosure(lib, &dateTime,   "time.dateTime"),
				"culture"d,      new MDClosure(lib, &culture,    "time.culture"),
				"timestamp"d,    new MDClosure(lib, &timestamp,  "time.timestamp")
			);

			return 0;
		}, "time"));

		context.importModule("time");
	}

	int microTime(MDState s, uint numParams)
	{
		version(Windows)
		{
			ulong time;
			QueryPerformanceCounter(&time);

			if(time < 0x8637BD05AF6L)
				s.push((time * 1_000_000) / performanceFreq);
			else
				s.push((time / performanceFreq) * 1_000_000);
		}
		else
		{
			timeval tv;
			gettimeofday(&tv, null);
			s.push(tv.tv_sec * 1_000_000L + tv.tv_usec);
		}
		
		return 1;
	}
	
	int dateString(MDState s, uint numParams)
	{
		Time time;
		char[40] buffer;
		char[] format = "G";
		Culture culture = null;

		if(numParams > 0)
			format = s.getParam!(char[])(0);

		if(numParams > 1 && !s.isParam!("null")(1))
			time = TableToTime(s, s.getParam!(MDTable)(1));
		else if(format == "R")
			time = Clock.now;
		else
			time = WallClock.now;

		if(numParams > 2)
			culture = s.safeCode(Culture.getCulture(s.getParam!(char[])(2)));

		s.push(s.safeCode(formatDateTime(buffer, time, format, culture)));
		return 1;
	}
	
	int dateTime(MDState s, uint numParams)
	{
		bool useGMT = false;
		MDTable t = null;
		
		if(numParams > 0)
		{
			if(s.isParam!("bool")(0))
			{
				useGMT = s.getParam!(bool)(0);
				
				if(numParams > 1)
					t = s.getParam!(MDTable)(1);
			}
			else
				t = s.getParam!(MDTable)(0);
		}

		s.push(DateTimeToTable(s, useGMT ? Clock.toDate : WallClock.toDate, t));
		return 1;
	}

	int culture(MDState s, uint numParams)
	{
		s.push(Culture.current.name);

		if(numParams > 0)
			Culture.current = s.safeCode(Culture.getCulture(s.getParam!(char[])(0)));

		return 1;
	}

	Time TableToTime(MDState s, MDTable tab)
	{
		MDValue table = MDValue(tab);
		Time time;

		with(s)
		{
			MDValue year = idx(table, YearString);
			MDValue month = idx(table, MonthString);
			MDValue day = idx(table, DayString);
			MDValue hour = idx(table, HourString);
			MDValue min = idx(table, MinString);
			MDValue sec = idx(table, SecString);

			if(!year.isInt() || !month.isInt() || !day.isInt())
				s.throwRuntimeException("year, month, and day fields in time table must exist and must be integers");

			if(hour.isInt() && min.isInt() && sec.isInt())
				time = Gregorian.generic.toTime(year.as!(int), month.as!(int), day.as!(int), hour.as!(int), min.as!(int), sec.as!(int), 0, 0);
			else
				time = Gregorian.generic.toTime(year.as!(int), month.as!(int), day.as!(int), 0, 0, 0, 0, 0);
		}

		return time;
	}

	MDTable DateTimeToTable(MDState s, DateTime time, MDTable dest)
	{
		if(dest is null)
			dest = new MDTable();

		MDValue table = dest;

		with(s)
		{
			idxa(table, YearString, MDValue(time.date.year));
			idxa(table, MonthString, MDValue(time.date.month));
			idxa(table, DayString, MDValue(time.date.day));
			idxa(table, HourString, MDValue(time.time.hours));
			idxa(table, MinString, MDValue(time.time.minutes));
			idxa(table, SecString, MDValue(time.time.seconds));
		}
		
		return dest;
	}
	
	int timestamp(MDState s, uint numParams)
	{
		s.push(cast(int)(Clock.now - Time.epoch1970).seconds);
		return 1;
	}

	static class MDPerfCounterClass : MDObject
	{
		static class MDPerfCounter : MDObject
		{
			protected StopWatch mWatch;
			protected mdfloat mTime = 0;
			
			public this(MDObject owner)
			{
				super("PerfCounter", owner);
			}
		}

		public this(MDObject owner)
		{
			super("PerfCounter", owner);

			fields.addList
			(
				"clone"d,     new MDClosure(fields, &clone,     "PerfCounter.clone"),
				"start"d,     new MDClosure(fields, &start,     "PerfCounter.start"),
				"stop"d,      new MDClosure(fields, &stop,      "PerfCounter.stop"),
				"seconds"d,   new MDClosure(fields, &seconds,   "PerfCounter.seconds"),
				"millisecs"d, new MDClosure(fields, &millisecs, "PerfCounter.millisecs"),
				"microsecs"d, new MDClosure(fields, &microsecs, "PerfCounter.microsecs")
			);
		}

		public int clone(MDState s, uint numParams)
		{
			s.push(new MDPerfCounter(this));
			return 1;
		}

		public int start(MDState s, uint numParams)
		{
			s.getContext!(MDPerfCounter).mWatch.start();
			return 0;
		}

		public int stop(MDState s, uint numParams)
		{
			auto self = s.getContext!(MDPerfCounter);
			self.mTime = self.mWatch.stop();
			return 0;
		}

		public int seconds(MDState s, uint numParams)
		{
			s.push(s.getContext!(MDPerfCounter).mTime);
			return 1;
		}

		public int millisecs(MDState s, uint numParams)
		{
			s.push(s.getContext!(MDPerfCounter).mTime * 1_000);
			return 1;
		}

		public int microsecs(MDState s, uint numParams)
		{
			s.push(s.getContext!(MDPerfCounter).mTime * 1_000_000);
			return 1;
		}
	}
}