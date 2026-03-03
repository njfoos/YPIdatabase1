-- DROP SCHEMA public;

CREATE SCHEMA public AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public IS 'standard public schema';
-- public."Metric Definitions" definition

-- Drop table

-- DROP TABLE public."Metric Definitions";

CREATE TABLE public."Metric Definitions" (
	metric_name varchar NULL,
	metric_description text NULL,
	metric_formula text NULL,
	metric_type varchar NULL, -- raw, computed, benchmark, differential
	metric_definitionsid int4 NOT NULL,
	CONSTRAINT "metric_definitionsID" PRIMARY KEY (metric_definitionsid)
);
COMMENT ON TABLE public."Metric Definitions" IS 'Created + worked on by Natalie
The metric definitions table stores the metadata for each metric. This table acts as the reference for all metrics, helping to ensure any calculation in reports, dashboards, or materialized views references a standard definition.';

-- Column comments

COMMENT ON COLUMN public."Metric Definitions".metric_type IS 'raw, computed, benchmark, differential';


-- public."Time Dimension" definition

-- Drop table

-- DROP TABLE public."Time Dimension";

CREATE TABLE public."Time Dimension" (
	dateid date NOT NULL,
	"year" int4 NULL,
	"month" int4 NULL,
	week int4 NULL,
	quarter int4 NULL,
	is_month_end bool NULL,
	CONSTRAINT "dateID" PRIMARY KEY (dateid)
);
COMMENT ON TABLE public."Time Dimension" IS 'Created + worked on by Natalie
The Time Dimension table supports temporal analysis and enables grouping by day/week/month/quarter. This table will join raw metrics and follower info to enable trending, time-series analysis, and computing normalized/expected metrics over consistent windows.';


-- public.creator definition

-- Drop table

-- DROP TABLE public.creator;

CREATE TABLE public.creator (
	creatorid int4 NOT NULL,
	creator_name varchar NULL,
	creator_email varchar NULL,
	creator_date date NULL, -- Start date of being a creator
	CONSTRAINT "creator_ID" PRIMARY KEY (creatorid)
);
COMMENT ON TABLE public.creator IS 'Created by Natalie and Harini, DBeaver work was done by Natalie
The creator table holds information about the content creators. This is linked to raw metrics, sponsored content, and audience alignment metrics, and will support calculations like CNA, tAS, ER+, and expected metrics.';

-- Column comments

COMMENT ON COLUMN public.creator.creator_date IS 'Start date of being a creator';


-- public.niche definition

-- Drop table

-- DROP TABLE public.niche;

CREATE TABLE public.niche (
	nicheid int4 NOT NULL,
	niche_name varchar NULL,
	CONSTRAINT "nicheID" PRIMARY KEY (nicheid)
);
COMMENT ON TABLE public.niche IS 'Created + worked on by Natalie
The niche table holds information about the niche category content that falls into, which can later be used to derive niche-specific requesting metrics.';


-- public.platform definition

-- Drop table

-- DROP TABLE public.platform;

CREATE TABLE public.platform (
	platformid int4 NOT NULL, -- 1 = Facebook¶2 = Instagram¶3 = TikTok¶4 = Twitter¶5 = Snapchat¶6 = LinkedIn¶7 = YouTube¶8 = Twitch¶9 = Rumble¶10 = Reddit¶11 = Pintrest
	platform_name varchar NULL,
	CONSTRAINT "platformID" PRIMARY KEY (platformid)
);
COMMENT ON TABLE public.platform IS 'Created by Natalie and Harini, all work on DBeaver was done by Natalie
The platform tablecontains information about each platform on which content is created. Will be used for normalization in ER, ER+, xER, and differential metrics.';

-- Column comments

COMMENT ON COLUMN public.platform.platformid IS '1 = Facebook
2 = Instagram
3 = TikTok
4 = Twitter
5 = Snapchat
6 = LinkedIn
7 = YouTube
8 = Twitch
9 = Rumble
10 = Reddit
11 = Pintrest';


-- public."Creator Keyword Metric CNA" definition

-- Drop table

-- DROP TABLE public."Creator Keyword Metric CNA";

CREATE TABLE public."Creator Keyword Metric CNA" (
	c_keywordid int4 NOT NULL,
	creatorid int4 NULL,
	keyword varchar NULL,
	frequency_weight float4 NULL,
	CONSTRAINT "c_keywordID" PRIMARY KEY (c_keywordid),
	CONSTRAINT creator_fk FOREIGN KEY (creatorid) REFERENCES public.creator(creatorid)
);
COMMENT ON TABLE public."Creator Keyword Metric CNA" IS 'Created + worked on by Natalie
The creator keyword metrics table stores the creator-defined keywords for content. This table will be used for the creator niche alignment (CNA) metric to determine the relevance between the creator’s content and advertiser intent. It will also support the Total Alignment Score (tAS) calculations.';


-- public."Creator platform profiles" definition

-- Drop table

-- DROP TABLE public."Creator platform profiles";

CREATE TABLE public."Creator platform profiles" (
	profileid int4 NOT NULL,
	followers int4 NULL,
	total_videos int4 NULL,
	total_posts int4 NULL,
	total_spon_videos int4 NULL,
	total_spon_min float4 NULL,
	last_updated date NULL,
	creatorid int4 NULL,
	platformid int4 NULL,
	CONSTRAINT "profileID" PRIMARY KEY (profileid),
	CONSTRAINT creator_fk FOREIGN KEY (creatorid) REFERENCES public.creator(creatorid),
	CONSTRAINT platform_fk FOREIGN KEY (platformid) REFERENCES public.platform(platformid)
);
COMMENT ON TABLE public."Creator platform profiles" IS 'Created + worked on by Natalie
The creator platform profiles table resolves the many-to-many relationship between creators and platforms.

 A creator can exist on multiple platforms.
 Each platform profile has different followers, content, and performance, so this is where all that data will be stored.';


-- public."Follower Information" definition

-- Drop table

-- DROP TABLE public."Follower Information";

CREATE TABLE public."Follower Information" (
	follower_snapshotid int4 NOT NULL,
	profileid int4 NULL,
	followers int4 NULL,
	recorded_at timestamp NOT NULL,
	dateid date NULL,
	CONSTRAINT "follower_snapshotID" PRIMARY KEY (follower_snapshotid),
	CONSTRAINT "dateID_fk" FOREIGN KEY (dateid) REFERENCES public."Time Dimension"(dateid),
	CONSTRAINT "profileID_fk" FOREIGN KEY (profileid) REFERENCES public."Creator platform profiles"(profileid)
);
COMMENT ON TABLE public."Follower Information" IS 'Created + worked on by Natalie
The follower information table tracks the size and dynamics of a creator’s audience over time. It will be used for Follower Growth Rate (FGR, FGR+, xFGR, dFGR) calculations and contextualizing engagement rates relative to audience size.';


-- public."Platform Benchmarks" definition

-- Drop table

-- DROP TABLE public."Platform Benchmarks";

CREATE TABLE public."Platform Benchmarks" (
	benchmarkid int4 NOT NULL,
	median_er float4 NULL,
	median_watch_time float4 NULL,
	median_growth_rate float4 NULL,
	expected_share_rate float4 NULL,
	expected_save_rate float4 NULL,
	calculated_at date NULL,
	platformid int4 NULL,
	nicheid int4 NULL,
	calculation_window_start date NULL,
	calculation_window_end date NULL,
	metric_version int4 NULL,
	CONSTRAINT "benchmarkID" PRIMARY KEY (benchmarkid),
	CONSTRAINT niche_fk FOREIGN KEY (nicheid) REFERENCES public.niche(nicheid),
	CONSTRAINT platform_fk FOREIGN KEY (platformid) REFERENCES public.platform(platformid)
);
COMMENT ON TABLE public."Platform Benchmarks" IS 'Created + worked on by Natalie
The Platform Benchmarks table stores ecosystem-level performance baselines.

 These are the reference values that will allow us to compute: ER+
, 
WatchTime+, 

FGR+

, expected metrics, and 

differential metrics.';


-- public.audience definition

-- Drop table

-- DROP TABLE public.audience;

CREATE TABLE public.audience (
	audienceid int4 NOT NULL,
	creatorid_fk int4 NULL,
	CONSTRAINT "audienceID" PRIMARY KEY (audienceid),
	CONSTRAINT "creatorID_fk" FOREIGN KEY (creatorid_fk) REFERENCES public.creator(creatorid) ON DELETE SET NULL
);
COMMENT ON TABLE public.audience IS 'Created by Natalie and Harini, all DBeaver work was done by Natalie
The audience table stores demographic or aggregated audience characteristics of a creator’s platform profile.';


-- public."content" definition

-- Drop table

-- DROP TABLE public."content";

CREATE TABLE public."content" (
	contentid int4 NOT NULL,
	publish_datetime timestamp NULL,
	content_type varchar NULL,
	video_length_sec float4 NULL,
	spon_flag bool NULL,
	profileid int4 NULL,
	CONSTRAINT "contentID" PRIMARY KEY (contentid),
	CONSTRAINT profile_fk FOREIGN KEY (profileid) REFERENCES public."Creator platform profiles"(profileid)
);
COMMENT ON TABLE public."content" IS 'Created + worked on by Natalie
The content table is used to hold information about the individual content produced by a creator. This will help determine major metrics like ER, which is used multiple times, watch time, share rate, save rate, and the differential metrics.';


-- public."Advertiser Keyword Metrics" definition

-- Drop table

-- DROP TABLE public."Advertiser Keyword Metrics";

CREATE TABLE public."Advertiser Keyword Metrics" (
	a_keywordid int4 NOT NULL,
	creatorid int4 NULL,
	a_keyword varchar NULL,
	a_frequency_weight float4 NULL,
	audienceid int4 NULL,
	CONSTRAINT "a_keywordID" PRIMARY KEY (a_keywordid),
	CONSTRAINT audience_fk FOREIGN KEY (audienceid) REFERENCES public.audience(audienceid),
	CONSTRAINT creator_fk FOREIGN KEY (creatorid) REFERENCES public.creator(creatorid)
);
COMMENT ON TABLE public."Advertiser Keyword Metrics" IS 'Created + worked on by Natalie
The advertiser keyword metrics table stores the advertiser-defined keywords for content. This table will be used for the creator niche alignment (CNA) metric to determine the relevance between the creator’s content and advertiser intent. It will also support the Total Alignment Score (tAS) calculations.';


-- public."Raw Metrics" definition

-- Drop table

-- DROP TABLE public."Raw Metrics";

CREATE TABLE public."Raw Metrics" (
	raw_metricid int4 NOT NULL,
	contentid int4 NULL,
	video_length float4 NULL,
	actual_metric float4 NULL, -- This is used in plus metrics, differential metrics, ...
	"views" int4 NULL,
	likes int4 NULL,
	"comments" int4 NULL,
	saves int4 NULL,
	shares int4 NULL,
	chat_messages int4 NULL,
	clicks int4 NULL,
	opens int4 NULL,
	unsubscribes int4 NULL,
	subscribers int4 NULL,
	watch_time float4 NULL,
	recorded_at timestamp NULL,
	dateid date NULL,
	CONSTRAINT "metricID" PRIMARY KEY (raw_metricid),
	CONSTRAINT content_fk FOREIGN KEY (contentid) REFERENCES public."content"(contentid),
	CONSTRAINT "dateID_fk" FOREIGN KEY (dateid) REFERENCES public."Time Dimension"(dateid)
);
COMMENT ON TABLE public."Raw Metrics" IS 'Created by Natalie and Harini, worked on by Natalie
The Raw Metrics table holds the unprocessed engagement and content metrics directly collected from platforms. This is the source data for all derived and advanced metrics. ER+, xER, differential metrics, and watch time plus metrics are computed from these raw numbers.';

-- Column comments

COMMENT ON COLUMN public."Raw Metrics".actual_metric IS 'This is used in plus metrics, differential metrics, ...';