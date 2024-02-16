--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5 (Debian 15.5-0+deb12u1)
-- Dumped by pg_dump version 15.5 (Debian 15.5-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: split_cidr(cidr, integer); Type: FUNCTION; Schema: public; Owner: apnic
--

CREATE FUNCTION public.split_cidr(net cidr, exc integer) RETURNS SETOF cidr
    LANGUAGE plpgsql
    AS $$
DECLARE
  r cidr;
  lower cidr;
  upper cidr;
BEGIN
  IF masklen(net) > 24 AND family(net) = 4 THEN RETURN; END IF;

  IF masklen(net) > 48 AND family(net) = 6 THEN RETURN; END IF;

  IF masklen(net) > exc THEN RETURN; END IF;

  lower = set_masklen(net, masklen(net)+1);
  upper = set_masklen( (lower | ~ netmask(lower)) + 1, masklen(lower));

  RETURN NEXT net;

  FOR r IN SELECT * from split_cidr(upper, exc)
  LOOP RETURN NEXT r;
  END LOOP;

  FOR r IN SELECT * from split_cidr(lower, exc)
  LOOP RETURN NEXT r;
  END LOOP;

  RETURN;

END $$;


ALTER FUNCTION public.split_cidr(net cidr, exc integer) OWNER TO apnic;

--
-- Name: split_cidr_count(cidr, integer); Type: FUNCTION; Schema: public; Owner: apnic
--

CREATE FUNCTION public.split_cidr_count(net cidr, exc integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  l integer;
  ml integer;
BEGIN

ml = masklen(net);

  IF family(net) = 4 THEN
	if exc > 24 THEN
		l = 24 - ml;
	ELSE
		l = exc - ml;
	END IF;
  END IF;

  IF family(net) = 6 THEN
	if exc > 48 THEN
		l = 48 - ml;
	ELSE
		l = exc - ml;
	END IF;
  END IF;

  RETURN (2^(l+1))-1;

END $$;


ALTER FUNCTION public.split_cidr_count(net cidr, exc integer) OWNER TO apnic;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _geocode_rir_economy; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public._geocode_rir_economy (
    rir text,
    economy_iso character varying(2)
);


ALTER TABLE public._geocode_rir_economy OWNER TO apnic;

--
-- Name: _geocode_subnet_data; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public._geocode_subnet_data (
    rir text,
    economy_iso character varying(2),
    prefix cidr
);


ALTER TABLE public._geocode_subnet_data OWNER TO apnic;

--
-- Name: _route_rpki_subnet_counts; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public._route_rpki_subnet_counts (
    subnet cidr,
    maxlen integer,
    expanded_count bigint,
    routed_count bigint,
    rir text,
    economy_iso character varying(2)
);


ALTER TABLE public._route_rpki_subnet_counts OWNER TO apnic;

--
-- Name: rpki_signed_routes; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public.rpki_signed_routes (
    "ASN" text,
    "IP Prefix" cidr,
    "Max Length" integer,
    "Trust Anchor" text,
    "Expires" bigint
);


ALTER TABLE public.rpki_signed_routes OWNER TO apnic;

--
-- Name: overlapping_signed_routes; Type: MATERIALIZED VIEW; Schema: public; Owner: apnic
--

CREATE MATERIALIZED VIEW public.overlapping_signed_routes AS
 SELECT array_agg(DISTINCT a."ASN") AS asns_subnet,
    array_agg(DISTINCT b."ASN") AS asns_supernet,
    a."IP Prefix" AS subnet,
    a."Max Length" AS subnet_maxlen,
    b."IP Prefix" AS supernet,
    b."Max Length" AS supernet_maxlen
   FROM (public.rpki_signed_routes a
     JOIN public.rpki_signed_routes b ON ((((a."IP Prefix")::inet << (b."IP Prefix")::inet) AND (masklen((a."IP Prefix")::inet) <= b."Max Length"))))
  GROUP BY a."IP Prefix", a."Max Length", b."IP Prefix", b."Max Length"
  WITH NO DATA;


ALTER TABLE public.overlapping_signed_routes OWNER TO apnic;

--
-- Name: report_bcp185_by_iso; Type: VIEW; Schema: public; Owner: apnic
--

CREATE VIEW public.report_bcp185_by_iso AS
 SELECT _route_rpki_subnet_counts.economy_iso,
    sum(_route_rpki_subnet_counts.expanded_count) AS "ROA Coverage",
    sum(_route_rpki_subnet_counts.routed_count) AS "Global Routes",
    to_char((((100)::double precision * (sum(_route_rpki_subnet_counts.routed_count))::double precision) / (sum(_route_rpki_subnet_counts.expanded_count))::double precision), 'fm000D00%'::text) AS "BCP185 Compliance"
   FROM public._route_rpki_subnet_counts
  WHERE (_route_rpki_subnet_counts.rir IS NOT NULL)
  GROUP BY _route_rpki_subnet_counts.economy_iso
UNION
 SELECT 'Global'::character varying AS economy_iso,
    sum(_route_rpki_subnet_counts.expanded_count) AS "ROA Coverage",
    sum(_route_rpki_subnet_counts.routed_count) AS "Global Routes",
    to_char((((100)::double precision * (sum(_route_rpki_subnet_counts.routed_count))::double precision) / (sum(_route_rpki_subnet_counts.expanded_count))::double precision), 'fm000D00%'::text) AS "BCP185 Compliance"
   FROM public._route_rpki_subnet_counts;


ALTER TABLE public.report_bcp185_by_iso OWNER TO apnic;

--
-- Name: report_bcp185_by_rir; Type: VIEW; Schema: public; Owner: apnic
--

CREATE VIEW public.report_bcp185_by_rir AS
 SELECT _route_rpki_subnet_counts.rir,
    sum(_route_rpki_subnet_counts.expanded_count) AS "ROA Coverage",
    sum(_route_rpki_subnet_counts.routed_count) AS "Global Routes",
    to_char((((100)::double precision * (sum(_route_rpki_subnet_counts.routed_count))::double precision) / (sum(_route_rpki_subnet_counts.expanded_count))::double precision), 'fm00D00%'::text) AS "BCP185 Compliance"
   FROM public._route_rpki_subnet_counts
  WHERE (_route_rpki_subnet_counts.rir IS NOT NULL)
  GROUP BY _route_rpki_subnet_counts.rir
UNION
 SELECT 'Global'::text AS rir,
    sum(_route_rpki_subnet_counts.expanded_count) AS "ROA Coverage",
    sum(_route_rpki_subnet_counts.routed_count) AS "Global Routes",
    to_char((((100)::double precision * (sum(_route_rpki_subnet_counts.routed_count))::double precision) / (sum(_route_rpki_subnet_counts.expanded_count))::double precision), 'fm00D00%'::text) AS "BCP185 Compliance"
   FROM public._route_rpki_subnet_counts;


ALTER TABLE public.report_bcp185_by_rir OWNER TO apnic;

--
-- Name: report_bcp185_combined; Type: VIEW; Schema: public; Owner: apnic
--

CREATE VIEW public.report_bcp185_combined AS
 SELECT _route_rpki_subnet_counts.rir,
    _route_rpki_subnet_counts.economy_iso,
    sum(_route_rpki_subnet_counts.expanded_count) AS "ROA Coverage",
    sum(_route_rpki_subnet_counts.routed_count) AS "Global Routes",
    to_char((((100)::double precision * (sum(_route_rpki_subnet_counts.routed_count))::double precision) / (sum(_route_rpki_subnet_counts.expanded_count))::double precision), 'fm000D00%'::text) AS "BCP185 Compliance"
   FROM public._route_rpki_subnet_counts
  GROUP BY _route_rpki_subnet_counts.rir, _route_rpki_subnet_counts.economy_iso;


ALTER TABLE public.report_bcp185_combined OWNER TO apnic;

--
-- Name: rir_allocations; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public.rir_allocations (
    rir text,
    economy_iso character varying(2),
    family character varying(4),
    prefix inet,
    size integer,
    allocation_date text,
    allocation_status text,
    extended text
);


ALTER TABLE public.rir_allocations OWNER TO apnic;

--
-- Name: routes; Type: TABLE; Schema: public; Owner: apnic
--

CREATE TABLE public.routes (
    dumptype text,
    exported text,
    protocol character(1),
    nexthop inet,
    asn bigint,
    prefix cidr,
    aspath text,
    origin text
);


ALTER TABLE public.routes OWNER TO apnic;

--
-- Name: _geocode_subnet_data_economy_iso_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _geocode_subnet_data_economy_iso_idx ON public._geocode_subnet_data USING btree (economy_iso);


--
-- Name: _geocode_subnet_data_prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _geocode_subnet_data_prefix_idx ON public._geocode_subnet_data USING gist (prefix inet_ops);


--
-- Name: _geocode_subnet_data_rir_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _geocode_subnet_data_rir_idx ON public._geocode_subnet_data USING btree (rir);


--
-- Name: _route_rpki_subnet_counts_economy_iso_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _route_rpki_subnet_counts_economy_iso_idx ON public._route_rpki_subnet_counts USING btree (economy_iso);


--
-- Name: _route_rpki_subnet_counts_rir_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _route_rpki_subnet_counts_rir_idx ON public._route_rpki_subnet_counts USING btree (rir);


--
-- Name: _route_rpki_subnet_counts_subnet_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX _route_rpki_subnet_counts_subnet_idx ON public._route_rpki_subnet_counts USING gist (subnet inet_ops);


--
-- Name: allocated_economy_iso_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_economy_iso_idx ON public.rir_allocations USING btree (economy_iso);


--
-- Name: allocated_prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_prefix_idx ON public.rir_allocations USING gist (prefix inet_ops);


--
-- Name: allocated_rir_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX allocated_rir_idx ON public.rir_allocations USING btree (rir);


--
-- Name: overlapping_signed_routres_supernet_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX overlapping_signed_routres_supernet_idx ON public.overlapping_signed_routes USING gist (supernet inet_ops);


--
-- Name: routes_prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX routes_prefix_idx ON public.routes USING gist (prefix inet_ops);


--
-- Name: rpki_signed_routes_ASN_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX "rpki_signed_routes_ASN_idx" ON public.rpki_signed_routes USING btree ("ASN");


--
-- Name: rpki_signed_routes_IP Prefix_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX "rpki_signed_routes_IP Prefix_idx" ON public.rpki_signed_routes USING gist ("IP Prefix" inet_ops);


--
-- Name: rpki_signed_routes_Trust Anchor_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX "rpki_signed_routes_Trust Anchor_idx" ON public.rpki_signed_routes USING btree ("Trust Anchor");


--
-- Name: rpki_signed_routes_masklen_idx; Type: INDEX; Schema: public; Owner: apnic
--

CREATE INDEX rpki_signed_routes_masklen_idx ON public.rpki_signed_routes USING btree (masklen(("IP Prefix")::inet));


--
-- PostgreSQL database dump complete
--

