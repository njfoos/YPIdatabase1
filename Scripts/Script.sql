--Drop Schema and Tables/Create Schema
--Best Practice to drop tables in reverse order that they are created to make sure all data is --properly dropped
-- Drop table Raw Metrics
DROP TABLE IF EXISTS public."Raw Metrics" CASCADE;
-- Drop table Advertiser Keyword Metrics
DROP TABLE IF EXISTS public."Advertiser Keyword Metrics" CASCADE;
-- Drop table Content
DROP TABLE IF EXISTS public."content" CASCADE;
-- Drop table Audience
DROP TABLE IF EXISTS public.audience CASCADE;
-- Drop table Platform Benchmarks
DROP TABLE IF EXISTS public."Platform Benchmarks" CASCADE;
-- Drop table Follower Information
DROP TABLE IF EXISTS public."Follower Information" CASCADE;
-- Drop table Creator Platform Profiles
DROP TABLE IF EXISTS public."Creator platform profiles" CASCADE;
-- Drop table Creator Keyword Metric CNA
DROP TABLE IF EXISTS public."Creator Keyword Metric CNA" CASCADE;
-- Drop table Platform
DROP TABLE IF EXISTS public.platform CASCADE;
-- Drop table Niche
DROP TABLE IF EXISTS public.niche CASCADE;
-- Drop table Creator
DROP TABLE IF EXISTS public.creator CASCADE;
-- Drop table Time Dimension
DROP TABLE IF EXISTS public."Time Dimension" CASCADE;
--Drop table Metric Definitions
DROP TABLE IF EXISTS public."Metric Definitions" CASCADE;
--Drop Schema Public
DROP SCHEMA IF EXISTS public CASCADE;
-- Create Schema and Tables
--Create Schema
CREATE SCHEMA public;
COMMENT ON SCHEMA public IS 'standard public schema';

--Create Table Metric Definitions
CREATE TABLE public."Metric Definitions" (
    metric_definitionsid INT4 NOT NULL,
    metric_name VARCHAR NOT NULL,
    metric_description TEXT,
    metric_formula TEXT,
    metric_type VARCHAR,
   CONSTRAINT "metric_definitionsid" PRIMARY KEY (metric_definitionsid),
    CONSTRAINT chk_metric_type
        CHECK (metric_type IN ('raw','computed','benchmark','differential'))
);

COMMENT ON TABLE public."Metric Definitions" IS 'Created + worked on by Natalie
The metric definitions table stores the metadata for each metric. This table acts as the reference for all metrics, helping to ensure any calculation in reports, dashboards, or materialized views references a standard definition.';

-- Column comments
COMMENT ON COLUMN public."Metric Definitions".metric_type IS 'raw, computed, benchmark, differential';

--Create table Time Dimension
CREATE TABLE public."Time Dimension" (
	dateid date NOT NULL,
	year int4 NULL,
	month int4 NULL,
	week int4 NULL,
	quarter int4 NULL,
	is_month_end bool NULL,
	CONSTRAINT "dateID" PRIMARY KEY (dateid)
);
COMMENT ON TABLE public."Time Dimension" IS 'Created + worked on by Natalie
The Time Dimension table supports temporal analysis and enables grouping by day/week/month/quarter. This table will join raw metrics and follower info to enable trending, time-series analysis, and computing normalized/expected metrics over consistent windows.';

--Create Table Creator
CREATE TABLE public.creator (
	creatorid int4 NOT NULL,
	creator_name VARCHAR NOT NULL,
   	 creator_email VARCHAR UNIQUE,
   	 creator_date DATE,
	CONSTRAINT "creator_ID" PRIMARY KEY (creatorid)
);
COMMENT ON TABLE public.creator IS 'Created by Natalie and Harini, DBeaver work was done by Natalie
The creator table holds information about the content creators. This is linked to raw metrics, sponsored content, and audience alignment metrics, and will support calculations like CNA, tAS, ER+, and expected metrics.';

-- Column comments
COMMENT ON COLUMN public.creator.creator_date IS 'Start date of being a creator';

--Create Table Niche
CREATE TABLE public.niche (
	nicheid int4 NOT NULL,
	niche_name varchar NULL,
	CONSTRAINT "nicheID" PRIMARY KEY (nicheid)
);
COMMENT ON TABLE public.niche IS 'Created + worked on by Natalie
The niche table holds information about the niche category content that falls into, which can later be used to derive niche-specific requesting metrics.';

--Create table Platform
CREATE TABLE public.platform (
	platformid int4 NOT NULL,
	platform_name varchar NULL,
	CONSTRAINT "platformID" PRIMARY KEY (platformid)
);

COMMENT ON TABLE public.platform IS 'Created by Natalie and Harini, all work on DBeaver was done by Natalie
The platform table contains information about each platform on which content is created. Will be used for normalization in ER, ER+, xER, and differential metrics.';

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

--Create Table Creator Keyword Metric CNA
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

--Create table Creator Platform Profiles
CREATE TABLE public."Creator platform profiles" (
	profileid int4 NOT NULL,
	profile_name varchar NULL,
	followers int4 NULL CHECK (followers >= 0),
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
The creator platform profiles table resolves the many-to-many relationship between creators and platforms. A creator can exist on multiple platforms.
 Each platform profile has different followers, content, and performance, so this is where all that data will be stored.';

--Create Table Follower Information
CREATE TABLE public."Follower Information" (
	follower_snapshotid int4 NOT NULL,
	profileid int4 NULL,
	creatorid int4 NULL,
	followers int4 NULL,
	recorded_at timestamp NOT NULL,
	dateid date NULL,
	CONSTRAINT "follower_snapshotID" PRIMARY KEY (follower_snapshotid),
	CONSTRAINT "dateID_fk" FOREIGN KEY (dateid) REFERENCES public."Time Dimension"(dateid),
	CONSTRAINT "profileID_fk" FOREIGN KEY (profileid) REFERENCES public."Creator platform profiles"(profileid),
	CONSTRAINT "creatorID_fk" FOREIGN KEY (creatorid) REFERENCES public.creator (creatorid)
);
COMMENT ON TABLE public."Follower Information" IS 'Created + worked on by Natalie
The follower information table tracks the size and dynamics of a creator’s audience over time. It will be used for Follower Growth Rate (FGR, FGR+, xFGR, dFGR) calculations and contextualizing engagement rates relative to audience size.';


--Create Table Platform Benchmarks
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
The Platform Benchmarks table stores ecosystem-level performance baselines. These are the reference values that will allow us to compute: ER+, WatchTime+, FGR+, expected metrics, and differential metrics.';

--Create table Audience
CREATE TABLE public.audience (
	audienceid int4 NOT NULL,
	creatorid_fk int4 NULL,
	CONSTRAINT "audienceID" PRIMARY KEY (audienceid),
	CONSTRAINT "creatorID_fk" FOREIGN KEY (creatorid_fk) REFERENCES public.creator(creatorid) ON DELETE SET NULL
);
COMMENT ON TABLE public.audience IS 'Created by Natalie and Harini, all DBeaver work was done by Natalie
The audience table stores demographic or aggregated audience characteristics of a creator’s platform profile.';

--Create table Content
CREATE TABLE public."content" (
	contentid int4 NOT NULL,
	publish_datetime timestamp NULL,
	content_type varchar NULL,
	video_length_sec float4 NULL CHECK (video_length_sec >= 0),
	spon_flag bool NULL DEFAULT FALSE,
	profileid int4 NULL,
	CONSTRAINT "contentID" PRIMARY KEY (contentid),
	CONSTRAINT profile_fk FOREIGN KEY (profileid) REFERENCES public."Creator platform profiles"(profileid)
);
COMMENT ON TABLE public."content" IS 'Created + worked on by Natalie
The content table is used to hold information about the individual content produced by a creator. This will help determine major metrics like ER, which is used multiple times, watch time, share rate, save rate, and the differential metrics.';

--Create table Advertiser Keyword Metrics
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

--Create table Raw Metrics
CREATE TABLE public."Raw Metrics" (
	raw_metricid int4 NOT NULL,
	contentid int4 NULL,
	video_length float4 NULL,
	actual_metric float4 NULL, -- This is used in plus metrics, differential metrics, ...
	views int4 NULL CHECK (views >= 0),
	likes int4 NULL CHECK (likes >= 0),
	comments int4 NULL CHECK (comments >= 0),
	saves int4 NULL CHECK (saves >= 0),
	shares int4 NULL CHECK (likes >= 0),
	chat_messages int4 NULL,
	clicks int4 NULL,
	opens int4 NULL,
	unsubscribes int4 NULL,
	subscribers int4 NULL,
	watch_time float4 NULL CHECK (watch_time >= 0),
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
--Altering Tables/Constraints
--Alter table and constraints scripts written by Harini, edited by Natalie

ALTER TABLE public.creator
ALTER COLUMN creator_name SET NOT NULL;

ALTER TABLE public.platform
ALTER COLUMN platform_name SET NOT NULL;

ALTER TABLE public."content"
ALTER COLUMN spon_flag SET DEFAULT FALSE;

ALTER TABLE public."Creator platform profiles"
ADD CONSTRAINT chk_followers_nonnegative CHECK (followers >= 0);

ALTER TABLE public."Creator platform profiles"
ADD CONSTRAINT chk_total_videos_nonnegative CHECK (total_videos >= 0);

ALTER TABLE public."Creator platform profiles"
ADD CONSTRAINT chk_total_posts_nonnegative CHECK (total_posts >= 0);

ALTER TABLE public."Creator platform profiles"
ADD CONSTRAINT chk_total_spon_videos_nonnegative CHECK (total_spon_videos >= 0);

ALTER TABLE public."Creator platform profiles"
ADD CONSTRAINT chk_total_spon_min_nonnegative CHECK (total_spon_min >= 0);

ALTER TABLE public."content"
ADD CONSTRAINT chk_video_length_nonnegative CHECK (video_length_sec >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_views_nonnegative CHECK (views >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_likes_nonnegative CHECK (likes >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_comments_nonnegative CHECK (comments >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_shares_nonnegative CHECK (shares >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_saves_nonnegative CHECK (saves >= 0);

ALTER TABLE public."Raw Metrics"
ADD CONSTRAINT chk_watch_time_nonnegative CHECK (watch_time >= 0);

-- Optional but good practice
ALTER TABLE public.creator
ADD CONSTRAINT uq_creator_email UNIQUE (creator_email);
--Sample Data
--All the sample data was created by Natalie

--Sample Data for table Metric Definitions
--Creator Niche Alignment information
INSERT INTO public."Metric Definitions" values (1, 'Creator Niche Alignment', 'This is a raw score that indicates how suitable a certain creator is based on their advertiser key words and key words that are frequent thought out their content', 'CNA = 100 × (Σ (w_k × KeywordMatch_k)) / Σ w_kN', 'computed');
--Niche Adjusted Engagement Rate+ information
INSERT INTO public."Metric Definitions" values (2, 'Niche Adjusted Engagement Rate+', 'Niche Adjusted Engagement Rate+ adjusts a creator’s engagement rate based on Creator Niche Alignment to better reflect the quality and relevance of their audience. Rather than evaluating raw click-through or engagement rates in isolation, it contextualizes performance within the creator’s specific niche.
The goal is to highlight how influential a creator is within their own audience, not just how broadly engaging their content appears.', 'NAER+ = 100 × (ER / Median ER peer) × (0.5 + 0.5 × CNA/100)', 'computed');
--Total Alignment Score (tAS) information
INSERT INTO public."Metric Definitions" values (3, 'Total Alignment Score', '(Targeted Audience Score), a qualitative metric quantified to measure the Contextual Fit between the Creator, the Audience, and the Brand. This score aggregates several soft signals, including Niche Overlap (Does the channel topic align with the product?), Sentiment Analysis (Is the audiences response positive?), Brand Safety (Is the content free from controversy?), and Audience Demographics (Do the viewers match the target buyer persona?). tAS is analogous to the Culture Fit score in hiring, where a candidate may have high IQ (High Views) and great experience (High Retention) but lack the necessary synergy. Therefore, tAS functions as the essential Culture Fit score for our brand partnerships. When utilizing tAS, a score greater than 80 indicates high synergy, suggesting the ad will feel like an organic recommendation and result in conversion rates higher than the view count alone would predict. Conversely, a score below 50 signifies low synergy, meaning the ad will feel like an interruption; even with millions of views, conversion will likely be poor due to the Square Peg in a Round Hole effect.', 'tAS = 0.30Niche Overlap + 0.25Sentiment Analysis + 0.25Brand Safety + 0.20Audience Dem', 'computed');
--General ER+ information
INSERT INTO public."Metric Definitions" values (4, 'General ER+', 'Raw engagement rates are simple but misleading because average engagement levels vary widely. ER+ metrics use weighted adjustments and normalizations to a shared median baseline by considering factors such as:Content niche/category, Audience size and saturation effects, Platform-specific interaction behaviors (e.g., Twitter’s retweets vs. Instagram likes), Time period, content recency, and content type (video, image, text), Historical performance benchmarks for similar creators', 'ER+ = 100 x (weighted interactions / expected interactions)
Where: 
Weighted interactions = (interactionᵢ x weightᵢ)
Example weights: comment = 4, like = 1, save = 3', 'computed');
--XModels information
INSERT INTO public."Metric Definitions" values (5, 'XModels', 'Expected Engagement Rate (xER) is a model-based assessment tool designed to predict the baseline interaction level a creator should achieve given their audience size and platform saturation. This foundational model uses Algorithm Confidence signals such as the viral multiplier (Views/Followers ratio) and historical benchmarks to establish a Par Score for performance.','xER(v1 Conceptual model) = a·log(Followers) + b·Historical ER + c·Viral Multiplier + d·Posting Frequency', 'computed');
INSERT INTO public."Metric Definitions" values (6, 'Expected Watch Time', 'Expected Watch Time is a model-based assessment tool to evaluate the quality and efficiency of a social media page structure. This foundational model employs large-scale data and predictive analytics to project the optimal level for a channel/page based on specific input factors, such as subscriber count, upload frequency, and video length. The assessment ultimately answers the question: Based on your channel/page size and publishing volume, what should your watch time be if you were performing perfectly?', 'xWatchTime = Views × Average Retention × Video Length (minute details like color psychology, niche of the content, watching habits)', 'computed');
--Expected Growth (xFGR) information
INSERT INTO public."Metric Definitions" values (7, 'Expected Growth (xFGR)', 'The Follower Growth Rate (FGR) is an operational metric quantifying the percentage increase in audience size over a defined period, directly reflecting brand resonance and the virality of content. The FGR is calculated by capturing the net increase in followers (gains minus losses). While inherently volatile, this calculation is considered the most accurate measure of sustained audience interest. Maintaining an optimal FGR is critical for several strategic and operational reasons: it ensures operational continuity, provides resilience against inevitable algorithm changes, drives overall strategic growth, and significantly increases bargaining power during crucial sponsorship and negotiation discussions.', 'xFGR = αActivity + βIndustry Growth + γAccount Age⁻¹', 'computed');
--Differential Variants information
INSERT INTO public."Metric Definitions" values (8, 'Differential Variants',  'Differential metrics isolate true performance by measuring the residual between actual and expected performance.', 'dMetric = Actual - Expected', 'differential');
--Plus Metrics information
INSERT INTO public."Metric Definitions" values (9, 'Plus Metrics', 'Plus metrics standardize performance across platforms and niches by benchmarking results against the ecosystem median.', 'Metric+ = 100 x (Actual Metric / Median Metric)', 'computed');

--Sample Data for table Time Dimensions
INSERT INTO public."Time Dimension" values (date '2026-3-31', 2026, 3, 14, 1, TRUE);
INSERT INTO public."Time Dimension" values (date '2026-3-29', 2026, 3, 14, 1, TRUE);
INSERT INTO public."Time Dimension" values (date '2026-3-24', 2026, 3, 13, 1, FALSE);
INSERT INTO public."Time Dimension" values (date '2026-3-22', 2026, 3, 13, 1, FALSE);
INSERT INTO public."Time Dimension" values (date '2026-3-10', 2026, 3, 11, 1, FALSE);

--Sample Data for Table Creator
--Mithun Banerjee
INSERT INTO public."creator" values (0001, 'Mithun Banerjee', 'mithunbanerjee@gmail.com', NULL);
--Andrew Friedson
INSERT INTO public."creator" values (0002, 'Andrew Friedson', 'info@friedsonformc.com', date '2010-4-5');
--Will Jawando
INSERT INTO public."creator" values (0003, 'Will Jawando', 'will@willjawando.com', date '2009-1-1');
--Laurie-Anne Sayles
INSERT INTO public."creator" values (0004, 'Laurie-Anne Sayles', 'councilmember.sayles@montgomerycountymd.gov', date '2022-12-1' );
--Karla Silverstre
INSERT INTO public."creator" values (0005, 'Karla Silvestre', 'karlasilvestre@hotmail.com', date '2014-3-21');
--Kate Stewart
INSERT INTO public."creator" values (0006, 'Kate Stewart', 'councilmember.stewart@montgomerycountymd.gov', date '2023-2-23');
--Kristin Mink
INSERT INTO public."creator" values (0007, 'Kristin Mink', 'councilmember.Mink@montgomerycountymd.gov', date '2019-1-1');
--Natali Fani-González
INSERT INTO public."creator" values (0008, 'Natali Fani-González', 'councilmember.Fani-Gonzalez@montgomerycountymd.gov', date '2014-1-1');
--John McCarthy
INSERT INTO public."creator" values (0009, 'John McCarthy', 'john.mccarthy@johnmccarthy.us', date '2021-1-1');
--Brenda M. Diaz
INSERT INTO public."creator" values (0010, 'Brenda M. Diaz', 'info@diazforboe.com', date '2024-3-3');

--Sample data for table Niche
INSERT INTO public."niche" values (001, 'Policy');
INSERT INTO public."niche" values (002, 'Progressive');
INSERT INTO public."niche" values (003, 'Community');
INSERT INTO public."niche" values (004, 'Education');
INSERT INTO public."niche" values (005, 'Activism');
INSERT INTO public."niche" values (006, 'Legal');

--Sample data for Platform
INSERT INTO platform values (1, 'Facebook');
INSERT INTO platform values (2, 'Instagram');
INSERT INTO platform values (3, 'TikTok');
INSERT INTO platform values (4, 'Twitter');
INSERT INTO platform values (5, 'Snapchat');
INSERT INTO platform values (6, 'LinkedIn');
INSERT INTO platform values (7, 'YouTube');
INSERT INTO platform values (8, 'Twitch');
INSERT INTO platform values (9, 'Rumble');
INSERT INTO platform values (10, 'Reddit');
INSERT INTO platform values (11, 'Pintrest');

--Sample Data for table Creator Keyword Metric CNA
--Mithun Banerjee
INSERT INTO public."Creator Keyword Metric CNA" values (1, 0001, 'public policy', 0.9);
INSERT INTO public."Creator Keyword Metric CNA" values (2, 0001, 'economic development', 0.8);
--Andrew Friedson
INSERT INTO public."Creator Keyword Metric CNA" values (3, 0002, 'budget reform', 0.85);
INSERT INTO public."Creator Keyword Metric CNA" values (4, 0002, 'tax policy', 0.75);
--Will Jawando
INSERT INTO public."Creator Keyword Metric CNA" values (5, 0003, 'social justice', 0.95);
INSERT INTO public."Creator Keyword Metric CNA" values (6, 0003, 'education equity', 0.9);
--Laurie-Anne Sayles
INSERT INTO public."Creator Keyword Metric CNA" values (7, 0004, 'community engagement', 0.85);
INSERT INTO public."Creator Keyword Metric CNA" values (8, 0004, 'local government', 0.8);
--Karla Silverstre
INSERT INTO public."Creator Keyword Metric CNA" values (9, 0005, 'education policy', 0.9);
INSERT INTO public."Creator Keyword Metric CNA" values (10, 0005, 'school funding', 0.85);
--Kate Stewart
INSERT INTO public."Creator Keyword Metric CNA" values (11, 0006, 'climate action', 0.9);
INSERT INTO public."Creator Keyword Metric CNA" values (12, 0006, 'grassroots organizing development', 0.95);
--Kristin Mink
INSERT INTO public."Creator Keyword Metric CNA" values (13, 0007, 'small business', 0.8);
INSERT INTO public."Creator Keyword Metric CNA" values (14, 0007, 'community development', 0.85);
--Natali Fani-González
INSERT INTO public."Creator Keyword Metric CNA" values (15, 0008, 'urban planning', 0.8);
INSERT INTO public."Creator Keyword Metric CNA" values (16, 0008, 'transportation', 0.75);
--John McCarthy
INSERT INTO public."Creator Keyword Metric CNA" values (17, 0009, 'public safety', 0.9);
INSERT INTO public."Creator Keyword Metric CNA" values (18, 0009, 'criminal justice', 0.85);
--Brenda M. Diaz
INSERT INTO public."Creator Keyword Metric CNA" values (19, 0010, 'education reform', 0.9);
INSERT INTO public."Creator Keyword Metric CNA" values (20, 0010, 'student success', 0.85);

--Sample data for table Creator Platform Profiles
--Mithun Banerjee’s twitter 
INSERT INTO public."Creator platform profiles" values (00001, '@m1thunbanerjee', 14, 0, 0, 0, 0, NULL, 0001, 4);
--Mithun Banerjee’s instagram
INSERT INTO public."Creator platform profiles" values (00002, 'mithunbanerjee2025', 48, 0, 2, 0, 0, date '2025-8-12', 0001, 2);
--Mithun Banerjee’s facebook 
INSERT INTO public."Creator platform profiles" values (00003, 'mithunbanerjee', 3200, NULL, 10000, NULL, NULL, date '2026-3-28', 0001, 1);
--Andrew Friedson’s twitter 
INSERT INTO public."Creator platform profiles" values (00004, '@Andrew_Friedson', 1432, 120, 5191, 0, 0, date '2026-3-14', 0002, 4);
--Andrew Friedson’s facebook 
INSERT INTO public."Creator platform profiles" values (00005, 'AndrewFriedsonMD', 6100, NULL, 1500, NULL, NULL, date '2026-3-25', 0002, 1);
--Andrew Friedson’s instagram
INSERT INTO public."Creator platform profiles" values (00006, 'amfriedson', 2462, 29, 982, 0, 0, date '2026-3-29', 0002, 2);
--Andrew Friedson’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00007, 'andrew-friedson', 5980, 3, 85, 0, 0, date '2026-3-14', 0002, 6);
--Will Jawando’s twitter
INSERT INTO public."Creator platform profiles" values (00008, '@WillJawando', 13300, 95, 10100, 0, 0, date '2026-3-27', 0003, 4);
--Will Jawando’s Facebooks
INSERT INTO public."Creator platform profiles" values (00009, 'WillJawando', 8400, NULL, 3000, NULL, NULL, date '2026-3-10', 0003, 1);
INSERT INTO public."Creator platform profiles" values (00010, 'Councilmemberjawando', 2700, NULL, 2100, NULL, NULL, date '2023-3-8', 0003, 1);
--Will Jawando’s Instagram 
INSERT INTO public."Creator platform profiles" values (00011, '@willjawando', 12400, 195, 1415, 0, 0, date '2026-3-26', 0003, 2);
--Will Jawando’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00012, 'will-jawando', 2877, 0, 90, 0, 0, date '2026-3-14', 0003, 6);
--Laurie-Anne Sayles’ Facebook
INSERT INTO public."Creator platform profiles" values (00013, 'CMSayles', 519, NULL, 818, NULL, NULL, date '2026-3-24', 0004, 1);
--Laurie-Anne Sayles’ twitter
INSERT INTO public."Creator platform profiles" values (00014, '@CM_Sayles', 1015, 62, 1715, 0, 0, date '2026-3-13', 0004, 4);
--Laurie-Anne Sayles’ Instagram 
INSERT INTO public."Creator platform profiles" values (00015, '@councilmembersayles', 1861, 76, 437, 0, 0, date '2026-3-24', 0004, 2);
--Laurie-Anne Sayles’ Youtube
INSERT INTO public."Creator platform profiles" values (00016, '@councilmembersayles', 6, 26, 4, 0, 0, date '2025-12-19', 0004, 7);
--Laurie-Anne Sayles’ LinkedIn
INSERT INTO public."Creator platform profiles" values (00017, 'laurieannesayles', 5992, 1, 402, 0, 0, date '2026-3-24', 0004, 6);
--Karla Silverstre’s Facebooks
INSERT INTO public."Creator platform profiles" values (00018, 'KarlaSilvestre4BOE', NULL, NULL, NULL, NULL, NULL, NULL, 0005, 1);
INSERT INTO public."Creator platform profiles" values (00019, 'karla.silvestre.39', 1700, NULL, 1200, NULL, NULL, date '2026-3-24', 0005, 1);
--Karla Silverstre’s Instagram 
INSERT INTO public."Creator platform profiles" values (00020, '@karla4countycouncil', 282, 5, 47, 0, 0, date '2026-3-29', 0005, 2);
--Karla Silverstre’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00021, 'karla-silvestre-b4ab624', 1295, 0, 28, 0, 0, date '2026-3-22', 0005, 6);
--Karla Silverstre’s twitter
INSERT INTO public."Creator platform profiles" values (00022, '@KarlaSilvestre6', 1214, 24, 2632, 0, 0, date '2023-11-27', 0005, 4);
--Kate Stewart’s Facebook
INSERT INTO public."Creator platform profiles" values (00023, 'cmkatestewart', 2300, NULL, 1000, NULL, NULL, date '2026-3-28', 0006, 1);
--Kate Stewart’s twitter
INSERT INTO public."Creator platform profiles" values (00024, '@cmkatestewart', 1656, 35, 1324, 0, 0, date '2025-10-15', 0006, 4);
--Kate Stewart’s Youtube
INSERT INTO public."Creator platform profiles" values (00025, '@CouncilmemberKateStewart', 5, 23, 0, 0, 0, date '2026-3-24', 0006, 7);
--Kate Stewart’s Instagram 
INSERT INTO public."Creator platform profiles" values (00026, '@cmkatestewart', 2406, 107, 988, 0, 0, date '2026-3-28', 0006, 2);
--Kate Stewart’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00027, 'kate-stewart-0884a35', 1709, 3, 78, 0, 0, date '2026-3-24', 0006, 6);
--Kristin Mink’s Facebooks
INSERT INTO public."Creator platform profiles" values (00028, 'Mink4MoCo', 1700, NULL, 551, NULL, NULL, date '2026-3-25', 0007, 1);
INSERT INTO public."Creator platform profiles" values (00029, 'CouncilmemberMink', 935, NULL, 296, NULL, NULL, date '2026-3-25', 0007, 1);
--Kristin Mink’s twitter
INSERT INTO public."Creator platform profiles" values (00030, '@CMKristinMink', 833, 28, 610, 0, 0, date '2025-7-2', 0007, 4);
--Kristin Mink’s Instagram 
INSERT INTO public."Creator platform profiles" values (00031, '@cmkristinmink', 1754, 40, 186, 0, 0, date '2026-3-25', 0007, 2);
--Kristin Mink’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00032, 'kristin-mink-35039529', 444, 0, 0, 0, 0, NULL, 0007, 6);
--Natali Fani-González’s Facebook
INSERT INTO public."Creator platform profiles" values (00033, 'NataliFGonzalez', NULL, NULL, NULL, NULL, NULL, date '2026-3-28', 0008, 1);
--Natali Fani-González’s Instagram 
INSERT INTO public."Creator platform profiles" values (00034, '@natalifanigonzalez', 1471, 29, 803, 0, 0, date '2026-3-28', 0008, 2);
--Natali Fani-González’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00035, 'natali-fani-gonzalez', 4335, 1, 85, 0, 0, date '2026-3-24', 0008, 6);
--John McCarthy’s Facebooks
INSERT INTO public."Creator platform profiles" values (00036, 'McCarthyMoCo', 582, NULL, 152, NULL, NULL, date '2022-12-9', 0009, 1);
INSERT INTO public."Creator platform profiles" values (00037, 'JohnMcCarthyforStatesAttorney', 1500, NULL, 52, NULL, NULL, date '2022-3-22', 0009, 1);
--John McCarthy’s Instagram 
INSERT INTO public."Creator platform profiles" values (00038, '@mccarthymoco', 953, 2, 39, 0, 0, date '2022-7-18', 0009, 2);
--Brenda M. Diaz’s Facebook
INSERT INTO public."Creator platform profiles" values (00039, 'diaz.for.boe', 68, NULL, 20, NULL, NULL, date '2026-3-27', 0010, 1);
--Brenda M. Diaz’s LinkedIn
INSERT INTO public."Creator platform profiles" values (00040, 'brenda-m-diaz', 38, 0, 0, 0, 0, NULL, 0010, 6);
--Brenda M. Diaz’s Instagram 
INSERT INTO public."Creator platform profiles" values (00041, '@diaz.4.boe', 50, 9, 16, 0, 0, date '2026-1-26', 0010, 2);

--Sample data for table Follower Information
--Mithun Banerjee
INSERT INTO public."Follower Information" values (0001, 0001, 00001, 14, to_timestamp('2026-03-29 10:38:33', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0002, 0001, 00002, 48, to_timestamp('2026-03-29 10:40:10', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0003, 0001, 00003, 3200, to_timestamp('2026-03-29 10:45:01', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Andrew Friedson
INSERT INTO public."Follower Information" values (0004, 0002, 00004, 1432, to_timestamp('2026-03-29 10:49:12', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0005, 0002, 00005, 6100, to_timestamp('2026-03-29 10:52:32', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0006, 0002, 00006, 2462, to_timestamp('2026-03-29 10:54:56', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0007, 0002, 00007, 5980, to_timestamp('2026-03-29 11:00:17', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Will Jawando
INSERT INTO public."Follower Information" values (0008, 0003, 00008, 13300, to_timestamp('2026-03-29 11:02:45', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0009, 0003, 00009, 8400, to_timestamp('2026-03-29 11:04:22', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0010, 0003, 00010, 2700, to_timestamp('2026-03-29 11:05:52', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0011, 0003, 00011, 12400, to_timestamp('2026-03-29 11:08:39', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0012, 0003, 00012, 2877, to_timestamp('2026-03-29 11:13:59', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Laurie-Anne Sayles
INSERT INTO public."Follower Information" values (0013, 0004, 00013, 519, to_timestamp('2026-03-29 11:15:03', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0014, 0004, 00014, 1015, to_timestamp('2026-03-29 11:17:40', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0015, 0004, 00015, 1861, to_timestamp('2026-03-29 11:19:27', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0016, 0004, 00016, 6, to_timestamp('2026-03-29 11:20:58', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0017, 0004, 00017, 5992, to_timestamp('2026-03-29 11:25:29', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Karla Silvestre
INSERT INTO public."Follower Information" values (0018, 0005, 00018, NULL, to_timestamp('2026-03-29 11:26:41', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0019, 0005, 00019, 1700, to_timestamp('2026-03-29 11:28:06', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0020, 0005, 00020, 282, to_timestamp('2026-03-29 11:30:14', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0021, 0005, 00021, 1295, to_timestamp('2026-03-29 11:33:20', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0022, 0005, 00022, 1214, to_timestamp('2026-03-29 11:35:17', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Kate Stewart
INSERT INTO public."Follower Information" values (0023, 0006, 00023, 2300, to_timestamp('2026-03-29 11:36:53', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0024, 0006, 00024, 1656, to_timestamp('2026-03-29 11:38:59', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0025, 0006, 00025, 5, to_timestamp('2026-03-29 11:40:02', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0026, 0006, 00026, 2406, to_timestamp('2026-03-29 11:43:40', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0027, 0006, 00027, 1709, to_timestamp('2026-03-29 11:46:35', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Kristin Mink
INSERT INTO public."Follower Information" values (0028, 0007, 00028, 1700, to_timestamp('2026-03-29 11:48:11', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0029, 0007, 00029, 935, to_timestamp('2026-03-29 11:49:55', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0030, 0007, 00030, 883, to_timestamp('2026-03-29 11:51:42', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0031, 0007, 00031, 1754, to_timestamp('2026-03-29 11:54:32', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
INSERT INTO public."Follower Information" values (0032, 0007, 00032, 444, to_timestamp('2026-03-29 11:55:48', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-29');
--Natali Fani-González
INSERT INTO public."Follower Information" values (0033, 0008, 00033, NULL, to_timestamp('2026-03-31 11:52:14', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0034, 0008, 00034, 1471, to_timestamp('2026-03-31 11:54:34', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0035, 0008, 00035, 4335, to_timestamp('2026-03-31 11:57:44', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
--John McCarthy
INSERT INTO public."Follower Information" values (0036, 0009, 00036, 582, to_timestamp('2026-03-31 11:59:02', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0037, 0009, 00037, 1500, to_timestamp('2026-03-31 12:01:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0038, 0009, 00038, 953, to_timestamp('2026-03-31 12:04:21', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
--Brenda M. Diaz
INSERT INTO public."Follower Information" values (0039, 0010, 00039, 68, to_timestamp('2026-03-31 12:06:11', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0040, 0010, 00040, 38, to_timestamp('2026-03-31 12:08:15', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');
INSERT INTO public."Follower Information" values (0041, 0010, 00041, 50, to_timestamp('2026-03-31 12:10:48', 'YYYY-MM-DD HH24:MI:SS'), date '2026-3-31');

--Sample data for table Platform Benchmarks
-- YouTube (7) - Policy
INSERT INTO public."Platform Benchmarks" values (1, 0.045, 320, 0.02, 0.01, 0.015, date '2026-03-31', 7, 001, date '2026-03-01', date '2026-03-31', 1);
-- Instagram (2) - Community
INSERT INTO public."Platform Benchmarks" values (2, 0.065, 45, 0.03, 0.025, 0.04, date '2026-03-31', 2, 003, date '2026-03-01', date '2026-03-31', 1);
-- TikTok (3) - Activism
INSERT INTO public."Platform Benchmarks" values (3, 0.085, 28, 0.05, 0.04, 0.035, date '2026-03-31', 3, 005, date '2026-03-01', date '2026-03-31', 1);
-- Facebook (1) - Policy
INSERT INTO public."Platform Benchmarks" values (4, 0.035, 210, 0.015, 0.02, 0.01, date '2026-03-31', 1, 001, date '2026-03-01', date '2026-03-31', 1);
-- LinkedIn (6) - Professional
INSERT INTO public."Platform Benchmarks" values (5, 0.025, 180, 0.01, 0.015, 0.02, date '2026-03-31', 6, 002, date '2026-03-01', date '2026-03-31', 1);
-- Twitter/X (4) - Political commentary
INSERT INTO public."Platform Benchmarks" values (6, 0.02, 15, 0.02, 0.03, 0.01, date '2026-03-31', 4, 005, date '2026-03-01', date '2026-03-31', 1);
-- Instagram (2) - Education
INSERT INTO public."Platform Benchmarks" values (7, 0.07, 50, 0.035, 0.03, 0.045, date '2026-03-31', 2, 004, date '2026-03-01', date '2026-03-31', 1);
-- TikTok (3) - Youth engagement
INSERT INTO public."Platform Benchmarks" values (8, 0.09, 30, 0.055, 0.045, 0.04, date '2026-03-31', 3, 002, date '2026-03-01', date '2026-03-31', 1);
-- YouTube (7) - Education
INSERT INTO public."Platform Benchmarks" values (9, 0.05, 400, 0.025, 0.015, 0.02, date '2026-03-31', 7, 004, date '2026-03-01', date '2026-03-31', 1);
-- Facebook (1) - Community
INSERT INTO public."Platform Benchmarks" values (10, 0.04, 220, 0.02, 0.025, 0.015, date '2026-03-31', 1, 003, date '2026-03-01', date '2026-03-31', 1);

--Sample data for table Audience
--Mithun Banerjee
INSERT INTO public."audience" values (001, 0001);
INSERT INTO public."audience" values (002, 0001);
INSERT INTO public."audience" values (003, 0001);
--Andrew Friedson
INSERT INTO public."audience" values (004, 0002);
INSERT INTO public."audience" values (005, 0002);
INSERT INTO public."audience" values (006, 0002);
INSERT INTO public."audience" values (007, 0002);
--Will Jawando
INSERT INTO public."audience" values (008, 0003);
INSERT INTO public."audience" values (009, 0003);
INSERT INTO public."audience" values (010, 0003);
INSERT INTO public."audience" values (011, 0003);
--Laurie-Anne Sayles
INSERT INTO public."audience" values (012, 0004);
INSERT INTO public."audience" values (013, 0004);
INSERT INTO public."audience" values (014, 0004);
INSERT INTO public."audience" values (015, 0004);
INSERT INTO public."audience" values (016, 0004);
--Karla Silvestre
INSERT INTO public."audience" values (017, 0005);
INSERT INTO public."audience" values (018, 0005);
INSERT INTO public."audience" values (019, 0005);
INSERT INTO public."audience" values (020, 0005);
--Kate Stewart
INSERT INTO public."audience" values (021, 0006);
INSERT INTO public."audience" values (022, 0006);
INSERT INTO public."audience" values (023, 0006);
INSERT INTO public."audience" values (024, 0006);
INSERT INTO public."audience" values (025, 0006);
--Kristin Mink
INSERT INTO public."audience" values (026, 0007);
INSERT INTO public."audience" values (027, 0007);
INSERT INTO public."audience" values (028, 0007);
INSERT INTO public."audience" values (029, 0007);
--Natali Fani-Gonzalez
INSERT INTO public."audience" values (030, 0008);
INSERT INTO public."audience" values (031, 0008);
INSERT INTO public."audience" values (032, 0008);
--John McCarthy
INSERT INTO public."audience" values (033, 0009);
INSERT INTO public."audience" values (034, 0009);
--Brenda M. Diaz
INSERT INTO public."audience" values (035, 0010);
INSERT INTO public."audience" values (036, 0010);
INSERT INTO public."audience" values (037, 0010);

--Sample data for table Content
-- Mithun Banerjee
INSERT INTO public."content" values (0001, to_timestamp('2026-03-29 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'text', NULL, FALSE, 00001);
INSERT INTO public."content" values (0002, to_timestamp('2026-03-28 14:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'image', NULL, FALSE, 00002);
-- Andrew Friedson
INSERT INTO public."content" values (0003, to_timestamp('2026-03-25 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 120, FALSE, 00004);
INSERT INTO public."content" values (0004, to_timestamp('2026-03-20 18:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 180, TRUE, 00006);
-- Will Jawando 
INSERT INTO public."content" values (0005, to_timestamp('2026-03-27 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 240, FALSE, 00008);
INSERT INTO public."content" values (0006, to_timestamp('2026-03-26 16:20:00', 'YYYY-MM-DD HH24:MI:SS'), 'image', NULL, FALSE, 00011);
-- Laurie-Anne Sayles
INSERT INTO public."content" values (0007, to_timestamp('2026-03-24 11:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 90, FALSE, 00014);
-- Karla Silvestre
INSERT INTO public."content" values (0008, to_timestamp('2026-03-24 13:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'image', NULL, FALSE, 00020);
-- Kate Stewart
INSERT INTO public."content" values (0009, to_timestamp('2026-03-28 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 210, FALSE, 00026);
-- Kristin Mink
INSERT INTO public."content" values (0010, to_timestamp('2026-03-25 15:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'image', NULL, FALSE, 00031);
--Natali Fani-Gonzalez
INSERT INTO public."content" values (0011, to_timestamp('2026-03-28 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 150, FALSE, 00034);
--John McCarthy
INSERT INTO public."content" values (0012, to_timestamp('2026-03-31 09:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'image', NULL, FALSE, 00038);
-- Brenda M. Diaz
INSERT INTO public."content" values (0013, to_timestamp('2026-03-27 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'video', 60, TRUE, 00041);

--Sample data for table Advertiser Keyword Metrics
--Mithun Banerjee
INSERT INTO public."Advertiser Keyword Metrics" values (1, 0001, 'economic growth', 0.9, 001);
--Andrew Friedson
INSERT INTO public."Advertiser Keyword Metrics" values (2, 0002, 'fiscal responsibility', 0.85, 004);
--Will Jawando
INSERT INTO public."Advertiser Keyword Metrics" values (3, 0003, 'equity', 0.95, 008);
--Laurie-Anne Sayles
INSERT INTO public."Advertiser Keyword Metrics" values (4, 0004, 'community outreach', 0.8, 012);
--Karla Silvestre
INSERT INTO public."Advertiser Keyword Metrics" values (5, 0005, 'education funding', 0.9, 017);
--Kate Stewart
INSERT INTO public."Advertiser Keyword Metrics" values (6, 0006, 'climate policy', 0.95, 021);
--Kristin Mink
INSERT INTO public."Advertiser Keyword Metrics" values (7, 0007, 'local business support', 0.85, 026);
--Natali Fani-Gonzalez
INSERT INTO public."Advertiser Keyword Metrics" values (8, 0008, 'infrastructure', 0.8, 030);
--John McCarthy
INSERT INTO public."Advertiser Keyword Metrics" values (9, 0009, 'law enforcement', 0.9, 033);
--Brenda M. Diaz
INSERT INTO public."Advertiser Keyword Metrics" values (10, 0010, 'school improvement', 0.9, 035);

--Sample data for table Raw Metrics
-- Mithun Banerjee
INSERT INTO public."Raw Metrics" values (0001, 0001, NULL, 0.02, 120, 10, 2, 1, 1, 0, 3, 0, 0, 0, NULL, to_timestamp('2026-03-29 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
INSERT INTO public."Raw Metrics" values (0002, 0002, NULL, 0.05, 200, 25, 5, 4, 3, 0, 6, 0, 0, 0, NULL, to_timestamp('2026-03-29 10:05:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
-- Andrew Friedson
INSERT INTO public."Raw Metrics" values (0003, 0003, 120, 0.04, 5000, 200, 40, 30, 25, 0, 50, 0, 0, 0, 8000, to_timestamp('2026-03-25 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-24');
INSERT INTO public."Raw Metrics" values (0004, 0004, 180, 0.06, 7000, 350, 60, 50, 45, 0, 120, 0, 5, 0, 15000, to_timestamp('2026-03-20 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-22');
-- Will Jawando
INSERT INTO public."Raw Metrics" values (0005, 0005, 240, 0.08, 15000, 900, 150, 120, 100, 0, 200, 0, 0, 0, 45000, to_timestamp('2026-03-27 13:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
INSERT INTO public."Raw Metrics" values (0006, 0006, NULL, 0.07, 8000, 600, 80, 90, 70, 0, 90, 0, 0, 0, NULL, to_timestamp('2026-03-26 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
-- Laurie-Anne Sayles
INSERT INTO public."Raw Metrics" values (0007, 0007, 90, 0.05, 2500, 120, 30, 20, 18, 0, 40, 0, 0, 0, 6000, to_timestamp('2026-03-24 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-24');
-- Karla Silvestre
INSERT INTO public."Raw Metrics" values (0008, 0008, NULL, 0.04, 900, 60, 10, 8, 6, 0, 15, 0, 0, 0, NULL, to_timestamp('2026-03-24 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-24');
-- Kate Stewart
INSERT INTO public."Raw Metrics" values (0009, 0009, 210, 0.06, 6000, 300, 55, 40, 35, 0, 80, 0, 0, 0, 12000, to_timestamp('2026-03-28 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
-- Kristin Mink
INSERT INTO public."Raw Metrics" values (0010, 0010, NULL, 0.045, 2200, 150, 25, 20, 18, 0, 30, 0, 0, 0, NULL, to_timestamp('2026-03-25 16:30:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');
-- Natali Fani-Gonzalez
INSERT INTO public."Raw Metrics" values (0011, 0011, 150, 0.055, 4000, 200, 45, 35, 30, 0, 60, 0, 0, 0, 9000, to_timestamp('2026-03-28 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-31');
-- John McCarthy
INSERT INTO public."Raw Metrics" values (0012, 0012, NULL, 0.03, 1200, 70, 12, 8, 7, 0, 20, 0, 0, 0, NULL, to_timestamp('2026-03-31 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-31');
-- Brenda M. Diaz 
INSERT INTO public."Raw Metrics" values (0013, 0013, 60, 0.025, 300, 20, 5, 3, 2, 0, 12, 0, 1, 0, 500, to_timestamp('2026-03-27 20:00:00', 'YYYY-MM-DD HH24:MI:SS'), date '2026-03-29');

--Functions
--Functions script written by Harini and Natalie

--Engagement Rate
CREATE OR REPLACE FUNCTION public.calculate_engagement_rate(
    likes INT4,
    comments INT4,
    shares INT4,
    saves INT4,
    views INT4
)
RETURNS FLOAT4
LANGUAGE sql
AS $$
    SELECT (COALESCE(likes,0) + COALESCE(comments,0) + COALESCE(shares,0) + COALESCE(saves,0))::FLOAT4
           / NULLIF(views,0);
$$;

-- Share Rate
CREATE OR REPLACE FUNCTION public.calculate_share_rate(
    shares INT4,
    views INT4
)
RETURNS FLOAT4 LANGUAGE sql AS $$
    SELECT COALESCE(shares,0)::FLOAT4 / NULLIF(views,0);
$$;

-- Save Rate
CREATE OR REPLACE FUNCTION public.calculate_save_rate(
    saves INT4,
    views INT4
)
RETURNS FLOAT4 LANGUAGE sql AS $$
    SELECT COALESCE(saves,0)::FLOAT4 / NULLIF(views,0);
$$;


--Watch Time Rate
CREATE OR REPLACE FUNCTION public.calculate_watch_time_rate(
    watch_time FLOAT4,
    views INT4,
    video_length FLOAT4
)
RETURNS FLOAT4
LANGUAGE sql
AS $$
    SELECT COALESCE(watch_time,0)
           / NULLIF(views * video_length, 0);
$$;

--Plus Metric
CREATE OR REPLACE FUNCTION public.calculate_plus_metric(
    actual_value FLOAT4,
    benchmark_value FLOAT4
)
RETURNS FLOAT4
LANGUAGE sql
AS $$
    SELECT 100 * COALESCE(actual_value,0)
           / NULLIF(benchmark_value,0);
$$;

--Differential Metric
CREATE OR REPLACE FUNCTION public.calculate_differential_metric(
    actual_value FLOAT4,
    benchmark_value FLOAT4
)
RETURNS FLOAT4
LANGUAGE sql
AS $$
    SELECT COALESCE(actual_value,0) - COALESCE(benchmark_value,0);
$$;


--Follower Growth Rate
CREATE OR REPLACE FUNCTION public.calculate_follower_growth_rate(
    old_followers INT4,
    new_followers INT4
)
RETURNS FLOAT4
LANGUAGE sql
AS $$
    SELECT (COALESCE(new_followers,0) - COALESCE(old_followers,0))::FLOAT
           / NULLIF(old_followers,0);
$$;

-- CNA 
CREATE OR REPLACE FUNCTION public.calculate_cna(
    creator_weight FLOAT4,
    advertiser_weight FLOAT4
)
RETURNS FLOAT4 LANGUAGE sql AS $$
    SELECT COALESCE(creator_weight,0) * COALESCE(advertiser_weight,0);
$$;


-- tAS 
CREATE OR REPLACE FUNCTION public.calculate_tas(
    niche_overlap FLOAT4,
    sentiment FLOAT4,
    brand_safety FLOAT4,
    audience_match FLOAT4
)
RETURNS FLOAT4 LANGUAGE sql AS $$
    SELECT 0.30 * COALESCE(niche_overlap,0)
         + 0.25 * COALESCE(sentiment,0)
         + 0.25 * COALESCE(brand_safety,0)
         + 0.20 * COALESCE(audience_match,0);
$$;

--Indexes
--index written by Natalie and Harini

CREATE INDEX idx_raw_content
ON public."Raw Metrics"(contentid);

CREATE INDEX idx_raw_date
ON public."Raw Metrics"(dateid);

CREATE INDEX idx_profile_creator
ON public."Creator platform profiles"(creatorid);

CREATE INDEX idx_profile_platform
ON public."Creator platform profiles"(platformid);

CREATE INDEX idx_creator_name
ON public.creator(creator_name);

CREATE INDEX idx_content_publish_date
ON public."content"(publish_datetime);

CREATE INDEX idx_follower_profile
ON public."Follower Information"(profileid);

--Views
--views script written by Natalie and Harini
CREATE OR REPLACE VIEW public.engagement_rate_view AS
SELECT
    rm.raw_metricid,
    rm.contentid,
    public.calculate_engagement_rate(
        rm.likes, rm.comments, rm.shares, rm.saves, rm.views
    ) AS engagement_rate
FROM public."Raw Metrics" rm;


CREATE OR REPLACE VIEW public.content_performance_view AS
SELECT
    rm.raw_metricid,
    rm.contentid,
    public.calculate_engagement_rate(rm.likes, rm.comments, rm.shares, rm.saves, rm.views) AS engagement_rate,
    public.calculate_share_rate(rm.shares, rm.views) AS share_rate,
    public.calculate_save_rate(rm.saves, rm.views) AS save_rate,
    public.calculate_watch_time_rate(rm.watch_time, rm.views, c.video_length_sec) AS watch_time_rate
FROM public."Raw Metrics" rm
JOIN public.content c ON rm.contentid = c.contentid;


CREATE OR REPLACE VIEW public.follower_growth_view AS
WITH follower_change AS (
    SELECT
        fi.profileid,
        MIN(fi.followers) AS start_followers,
        MAX(fi.followers) AS end_followers
    FROM public."Follower Information" fi
    GROUP BY fi.profileid
)
SELECT
    profileid,
    start_followers,
    end_followers,
    public.calculate_follower_growth_rate(start_followers, end_followers) AS follower_growth_rate
FROM follower_change;


CREATE OR REPLACE VIEW public.er_plus_view AS
SELECT
    rm.raw_metricid,
    c.profileid,
    cpp.platformid,
    public.calculate_engagement_rate(rm.likes, rm.comments, rm.shares, rm.saves, rm.views) AS actual_er,
    pb.median_er,
    public.calculate_plus_metric(
        public.calculate_engagement_rate(rm.likes, rm.comments, rm.shares, rm.saves, rm.views),
        pb.median_er
    ) AS er_plus,
    public.calculate_differential_metric(
        public.calculate_engagement_rate(rm.likes, rm.comments, rm.shares, rm.saves, rm.views),
        pb.median_er
    ) AS d_er
FROM public."Raw Metrics" rm
JOIN public."content" c
    ON rm.contentid = c.contentid
JOIN public."Creator platform profiles" cpp
    ON c.profileid = cpp.profileid
LEFT JOIN public."Platform Benchmarks" pb
    ON cpp.platformid = pb.platformid;


CREATE OR REPLACE VIEW public.watch_time_plus_view AS
SELECT
    rm.raw_metricid,
    c.profileid,
    cpp.platformid,
    public.calculate_watch_time_rate(rm.watch_time, rm.video_length) AS actual_watch_time_rate,
    pb.median_watch_time,
    public.calculate_plus_metric(
        public.calculate_watch_time_rate(rm.watch_time, rm.video_length),
        pb.median_watch_time
    ) AS watch_time_plus,
    public.calculate_differential_metric(
        public.calculate_watch_time_rate(rm.watch_time, rm.video_length),
        pb.median_watch_time
    ) AS d_watch_time
FROM public."Raw Metrics" rm
JOIN public."content" c
    ON rm.contentid = c.contentid
JOIN public."Creator platform profiles" cpp
    ON c.profileid = cpp.profileid
LEFT JOIN public."Platform Benchmarks" pb
    ON cpp.platformid = pb.platformid;


CREATE OR REPLACE VIEW public.creator_keyword_alignment_view AS
SELECT
    ckm.creatorid,
    akm.audienceid,
    ckm.keyword AS creator_keyword,
    akm.a_keyword AS advertiser_keyword,
    public.calculate_cna(ckm.frequency_weight, akm.a_frequency_weight) AS cna_score
FROM public."Creator Keyword Metric CNA" ckm
JOIN public."Advertiser Keyword Metrics" akm
    ON ckm.creatorid = akm.creatorid
   AND LOWER(ckm.keyword) = LOWER(akm.a_keyword);


CREATE OR REPLACE VIEW public.creator_performance_summary AS
WITH creator_avg AS (
    SELECT
        cpp.creatorid,
        AVG(public.calculate_engagement_rate(rm.likes, rm.comments, rm.shares, rm.saves, rm.views)) AS avg_er,
        AVG(rm.views) AS avg_views
    FROM public."Raw Metrics" rm
    JOIN public."content" c
        ON rm.contentid = c.contentid
    JOIN public."Creator platform profiles" cpp
        ON c.profileid = cpp.profileid
    GROUP BY cpp.creatorid
),
creator_fgr AS (
    SELECT
        cpp.creatorid,
        AVG(fgv.follower_growth_rate) AS avg_fgr
    FROM public.follower_growth_view fgv
    JOIN public."Creator platform profiles" cpp
        ON fgv.profileid = cpp.profileid
    GROUP BY cpp.creatorid
),
creator_cna AS (
    SELECT
        creatorid,
        AVG(cna_score) AS avg_cna
    FROM public.creator_keyword_alignment_view
    GROUP BY creatorid
)
SELECT
    ca.creatorid,
    ca.avg_er,
    ca.avg_views,
    COALESCE(cf.avg_fgr, 0) AS avg_fgr,
    COALESCE(cc.avg_cna, 0) AS avg_cna,
    public.calculate_tas(
        COALESCE(cc.avg_cna, 0),
        COALESCE(ca.avg_er, 0),
        COALESCE(cf.avg_fgr, 0)
    ) AS total_alignment_score
FROM creator_avg ca
LEFT JOIN creator_fgr cf
    ON ca.creatorid = cf.creatorid
LEFT JOIN creator_cna cc
    ON ca.creatorid = cc.creatorid;
--Roles/Users
--Roles/users script written by Natalie

CREATE ROLE analytics_user LOGIN PASSWORD 'analytics123';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;

CREATE ROLE analytics_admin LOGIN PASSWORD 'admin123';
GRANT ALL PRIVILEGES ON SCHEMA public TO analytics_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO analytics_admin;

--Select Statements to View Table or View
--Select statements script written by Natalie

--These are the select scripts that will show the whole table with all the sample data
SELECT * from public."Metric Definitions";
SELECT * from public."Time Dimension";
SELECT * from public.creator;
SELECT * from public.niche;
SELECT * from public.platform;
SELECT * from public."Creator Keyword Metric CNA";
SELECT * from public."Creator platform profiles";
SELECT * from public."Follower Information";
SELECT * from public."Platform Benchmarks";
SELECT * from public.audience;
SELECT * from public."content";
SELECT * from public."Advertiser Keyword Metrics";
SELECT * from public."Raw Metrics";

--These are the select scripts that will show the whole view
SELECT * from public.engagement_rate_view;
SELECT * from public.follower_growth_view;
SELECT * from public.er_plus_view;
SELECT * from public.watch_time_plus_view;
SELECT * from public.creator_keyword_alignment_view;
SELECT * from public.creator_performance_summary;
--Test Queries
--Test Queries are written by Natalie, these are used to show that the database works properly --and that all information is updated/modified as asked


--This query should get all the content information with creator information
SELECT 
    c.contentid,
    cr.creator_name,
    cpp.profile_name,
    c.content_type,
    c.publish_datetime
FROM public."content" c
JOIN public."Creator platform profiles" cpp
    ON c.profileid = cpp.profileid
JOIN public.creator cr
    ON cpp.creatorid = cr.creatorid;

--these statements will test the different functions directly
SELECT public.calculate_engagement_rate(100, 20, 10, 5, 1000) AS engagement_rate;
SELECT public.calculate_watch_time_rate(5000, 100, 60) AS watch_time_rate;
SELECT public.calculate_plus_metric(0.08, 0.04) AS er_plus;
SELECT public.calculate_differential_metric(0.08, 0.04) AS diff_metric;
SELECT public.calculate_follower_growth_rate(1000, 1200) AS growth_rate;

--This is a join statement that will join the content and raw metrics
SELECT 
    rm.contentid,
    rm.views,
    rm.likes,
    rm.comments,
    rm.shares,
    rm.saves
FROM public."Raw Metrics" rm
JOIN public."content" c
    ON rm.contentid = c.contentid;
--This is a join statement that will join together creator, profile, content, and metrics
SELECT 
    cr.creator_name,
    cpp.profile_name,
    rm.views,
    rm.likes
FROM public.creator cr
JOIN public."Creator platform profiles" cpp
    ON cr.creatorid = cpp.creatorid
JOIN public."content" c
    ON cpp.profileid = c.profileid
JOIN public."Raw Metrics" rm
    ON c.contentid = rm.contentid;

--This statement will show the top 5 creators by average engagement rate 
SELECT 
    creatorid,
    avg_er
FROM public.creator_performance_summary
ORDER BY avg_er DESC
LIMIT 5;

--This statement will show the creators with the highest follower growth
SELECT 
    creatorid,
    avg_fgr
FROM public.creator_performance_summary
ORDER BY avg_fgr DESC;

--This statement will show the content with the highest engagement
SELECT 
    contentid,
    engagement_rate
FROM public.engagement_rate_view
ORDER BY engagement_rate DESC
LIMIT 10;

--This statement will compare the actual ER with the benchmark
SELECT 
    raw_metricid,
    actual_er,
    median_er,
    er_plus,
    d_er
FROM public.er_plus_view
ORDER BY er_plus DESC;

--This is a query using an index, it will show all of the raw metrics that are dated March 29, 2026
SELECT *
FROM public."Raw Metrics"
WHERE dateid = '2026-03-29';

--This insert statement is used to test invalid data being entered into the creator table
--This statement should fail/return an error
INSERT INTO public.creator values (9999, NULL, 'test@test.com');

--These lines are used to test the permissions of the analytic_user role
--The data insertion statement should fail/return an error

SET ROLE analytics_user;
SELECT * FROM public.creator;  
INSERT INTO public.creator VALUES (9998, 'Test User', 'test@test.com', CURRENT_DATE); 
