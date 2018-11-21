class Constants

	# Statuses
	STATUS_DRAFT            = 0
	STATUS_ACTIVE           = 1
	STATUS_PENDING          = 2
	STATUS_REJECTED         = 6
	STATUS_COMPLETED        = 7
	STATUS_INACTIVE         = 9
	STATUS_DELETED          = 10
	STATUS_ARCHIVED         = 11


	# Days of Week
  DOW_SUNDAY              = 0
	DOW_MONDAY              = 1
	DOW_TUESDAY             = 2
	DOW_WEDNESDAY           = 3
	DOW_THURSDAY            = 4
	DOW_FRIDAY              = 5
	DOW_SATURDAY            = 6


	# Intervals & Frequencies
	INTERVAL_MINS_FIVE			= 10
	INTERVAL_MINS_FIFTEEN		= 11 # Every 15 minutes
	INTERVAL_MINS_THIRTY		= 12
	INTERVAL_HOURS_ONE			= 20 # Hourly
	INTERVAL_HOURS_TWO			= 21
	INTERVAL_HOURS_SIX			= 22
	INTERVAL_HOURS_TWELVE		= 23
	INTERVAL_DAYS_ONE				= 30 # Daily
	INTERVAL_WEEKS_ONE			= 40 # Weekly
	INTERVAL_MONTHS_ONE			= 50 # Monthly
	INTERVAL_MONTHS_TWO			= 51
	INTERVAL_MONTHS_THREE		= 52 # Quarterly
	INTERVAL_MONTHS_FOUR		= 53
	INTERVAL_MONTHS_SIX			= 55 # BiAnnually / Semiannual
	INTERVAL_YEARS_ONE			= 60 # Annually / Yearly
	INTERVAL_YEARS_TWO			= 61 # BiEnnially


  # SLOT Types
  SLOT_BREAKFAST = 1
  SLOT_LUNCH = 2
  SLOT_DINNER = 3
  SLOT_SNACK = 4
  SLOT_SAMPLE = 5


	# MISC STUFF
	DEFAULT_TIMEZONE					= "Central Time (US & Canada)"
	DEFAULT_DRIVING_DISTANCE 	= 5

  #Regexp
  EMAIL_REGEXP = /.+@.+\..+/
  
  SALES_REP_PARTNER_LIMIT = 1

end
