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

module minid.oslib;

import minid.types;
import minid.utils;

import tango.stdc.stdlib;
import tango.stdc.stringz;
import tango.sys.Environment;
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

class OSLib
{
	private static OSLib lib;
	private static MDValue YearString;
	private static MDValue MonthString;
	private static MDValue DayString;
	private static MDValue HourString;
	private static MDValue MinString;
	private static MDValue SecString;

	static this()
	{
		lib = new OSLib();
		
		YearString = new MDString("year"d);
		MonthString = new MDString("month"d);
		DayString = new MDString("day"d);
		HourString = new MDString("hour"d);
		MinString = new MDString("min"d);
		SecString = new MDString("sec"d);
	}
	
	private MDPerfCounterClass perfCounterClass;
	version(Windows) ulong performanceFreq;
	
	private this()
	{
		perfCounterClass = new MDPerfCounterClass();
		
		version(Windows)
		{
			if(!QueryPerformanceFrequency(&performanceFreq))
				performanceFreq = 0x7fffffffffffffffL;
		}
	}

	public static void init(MDContext context)
	{
		MDNamespace namespace = new MDNamespace("os"d, context.globals.ns);

		namespace.addList
		(
			"PerfCounter"d,  lib.perfCounterClass,
			"microTime"d,    new MDClosure(namespace, &lib.microTime,  "os.microTime"),
			"system"d,       new MDClosure(namespace, &lib.system,     "os.system"),
			"getEnv"d,       new MDClosure(namespace, &lib.getEnv,     "os.getEnv"),
			"dateString"d,   new MDClosure(namespace, &lib.dateString, "os.dateString"),
			"dateTime"d,     new MDClosure(namespace, &lib.dateTime,   "os.dateTime"),
			"culture"d,      new MDClosure(namespace, &lib.culture,    "os.culture")
		);

		context.globals["os"d] = namespace;
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
	
	int system(MDState s, uint numParams)
	{
		if(numParams == 0)
			s.push(.system(null) ? true : false);
		else
			s.push(.system(toStringz(s.getParam!(char[])(0))));

		return 1;
	}

	int getEnv(MDState s, uint numParams)
	{
		if(numParams == 0)
			s.push(Environment.get());
		else
		{
			char[] def = null;
			
			if(numParams > 1)
				def = s.getParam!(char[])(1);

			char[] val = Environment.get(s.getParam!(char[])(0), def);
			
			if(val is null)
				s.pushNull();
			else
				s.push(val);
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

	static Time TableToTime(MDState s, MDTable tab)
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

	static MDTable DateTimeToTable(MDState s, DateTime time, MDTable dest)
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

	static class MDPerfCounterClass : MDClass
	{
		public this()
		{
			super("PerfCounter", null);

			mMethods.addList
			(
				"start"d,     new MDClosure(mMethods, &start,     "PerfCounter.start"),
				"stop"d,      new MDClosure(mMethods, &stop,      "PerfCounter.stop"),
				"seconds"d,   new MDClosure(mMethods, &seconds,   "PerfCounter.seconds"),
				"millisecs"d, new MDClosure(mMethods, &millisecs, "PerfCounter.millisecs"),
				"microsecs"d, new MDClosure(mMethods, &microsecs, "PerfCounter.microsecs")
			);
		}

		public MDPerfCounter newInstance()
		{
			return new MDPerfCounter(this);
		}
		
		public int start(MDState s, uint numParams)
		{
			MDPerfCounter i = s.getContext!(MDPerfCounter);
			i.start();
			return 0;
		}
		
		public int stop(MDState s, uint numParams)
		{
			MDPerfCounter i = s.getContext!(MDPerfCounter);
			i.stop();
			return 0;
		}
		
		public int seconds(MDState s, uint numParams)
		{
			MDPerfCounter i = s.getContext!(MDPerfCounter);
			s.push(i.seconds());
			return 1;
		}
		
		public int millisecs(MDState s, uint numParams)
		{
			MDPerfCounter i = s.getContext!(MDPerfCounter);
			s.push(i.millisecs());
			return 1;
		}
		
		public int microsecs(MDState s, uint numParams)
		{
			MDPerfCounter i = s.getContext!(MDPerfCounter);
			s.push(i.microsecs());
			return 1;
		}
	}

	static class MDPerfCounter : MDInstance
	{
		protected StopWatch mWatch;
		protected mdfloat mTime = 0;

		public this(MDClass owner)
		{
			super(owner);
		}
		
		public final void start()
		{
			mWatch.start();
		}

		public final void stop()
		{
			mTime = mWatch.stop();
		}

		public final mdfloat seconds()
		{
			return mTime;
		}

		public final mdfloat millisecs()
		{
			return mTime * 1000;
		}

		public final mdfloat microsecs()
		{
			return mTime * 1000000;
		}
	}
}