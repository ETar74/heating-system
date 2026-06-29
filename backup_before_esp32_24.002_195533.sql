--
-- PostgreSQL database dump
--

\restrict HcEQ1OpXYshosiczyFvhDuTZYMd4ADbfpB7cNAn1VMd18AgcgE6OwEnRcfuxiew

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: commands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.commands (
    id integer NOT NULL,
    device_id integer NOT NULL,
    command text NOT NULL,
    payload jsonb,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    executed_at timestamp(3) without time zone
);


ALTER TABLE public.commands OWNER TO postgres;

--
-- Name: commands_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.commands_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commands_id_seq OWNER TO postgres;

--
-- Name: commands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.commands_id_seq OWNED BY public.commands.id;


--
-- Name: device_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_cache (
    id integer NOT NULL,
    device_id text NOT NULL,
    settings jsonb,
    telemetry jsonb,
    device_status jsonb,
    last_sync timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    uptime integer,
    firmware text
);


ALTER TABLE public.device_cache OWNER TO postgres;

--
-- Name: device_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.device_cache_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_cache_id_seq OWNER TO postgres;

--
-- Name: device_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.device_cache_id_seq OWNED BY public.device_cache.id;


--
-- Name: device_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_events (
    id integer NOT NULL,
    device_id text NOT NULL,
    event_id integer NOT NULL,
    "timestamp" timestamp(3) without time zone NOT NULL,
    type text NOT NULL,
    message text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.device_events OWNER TO postgres;

--
-- Name: device_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.device_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.device_events_id_seq OWNER TO postgres;

--
-- Name: device_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.device_events_id_seq OWNED BY public.device_events.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.devices (
    id integer NOT NULL,
    name text NOT NULL,
    serial_number text,
    firmware_version text,
    online boolean DEFAULT false NOT NULL,
    last_seen timestamp(3) without time zone,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.devices OWNER TO postgres;

--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.devices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.devices_id_seq OWNER TO postgres;

--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id integer NOT NULL,
    device_id integer,
    event_type text NOT NULL,
    message text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.events_id_seq OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: parameters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parameters (
    id integer NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    description text,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.parameters OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parameters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parameters_id_seq OWNER TO postgres;

--
-- Name: parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parameters_id_seq OWNED BY public.parameters.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: telemetry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telemetry (
    id integer NOT NULL,
    device_id integer NOT NULL,
    parameter text NOT NULL,
    value text NOT NULL,
    "timestamp" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.telemetry OWNER TO postgres;

--
-- Name: telemetry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telemetry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telemetry_id_seq OWNER TO postgres;

--
-- Name: telemetry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telemetry_id_seq OWNED BY public.telemetry.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    telegram_id bigint,
    role_id integer NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: commands id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commands ALTER COLUMN id SET DEFAULT nextval('public.commands_id_seq'::regclass);


--
-- Name: device_cache id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_cache ALTER COLUMN id SET DEFAULT nextval('public.device_cache_id_seq'::regclass);


--
-- Name: device_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_events ALTER COLUMN id SET DEFAULT nextval('public.device_events_id_seq'::regclass);


--
-- Name: devices id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: parameters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters ALTER COLUMN id SET DEFAULT nextval('public.parameters_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: telemetry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telemetry ALTER COLUMN id SET DEFAULT nextval('public.telemetry_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: commands; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.commands (id, device_id, command, payload, status, created_at, executed_at) FROM stdin;
\.


--
-- Data for Name: device_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_cache (id, device_id, settings, telemetry, device_status, last_sync, uptime, firmware) FROM stdin;
\.


--
-- Data for Name: device_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_events (id, device_id, event_id, "timestamp", type, message, created_at) FROM stdin;
\.


--
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.devices (id, name, serial_number, firmware_version, online, last_seen, created_at) FROM stdin;
1	ESP32-Heating-Controller	ESP32-001	\N	f	\N	2026-06-21 08:50:08.133
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (id, device_id, event_type, message, created_at) FROM stdin;
1	\N	INFO	User admin logged in	2026-06-21 08:54:16.808
2	\N	INFO	User qqq created by admin	2026-06-21 11:49:00.01
3	\N	INFO	User admin logged in	2026-06-22 05:04:20.688
4	\N	INFO	User admin logged in	2026-06-22 05:33:43.473
5	\N	INFO	User admin logged in	2026-06-23 09:34:23.056
6	\N	INFO	User admin logged out	2026-06-23 09:49:46.122
7	\N	INFO	User qqq logged in	2026-06-23 09:49:59.993
8	\N	INFO	User qqq logged out	2026-06-23 09:51:23.001
9	\N	INFO	User admin logged in	2026-06-23 09:51:25.186
10	\N	INFO	User admin logged out	2026-06-23 09:51:39.805
11	\N	INFO	User qqq logged in	2026-06-23 09:51:44.81
12	\N	INFO	User qqq logged out	2026-06-23 09:52:24.421
13	\N	INFO	User admin logged in	2026-06-23 09:52:25.799
14	\N	INFO	User admin logged out	2026-06-23 09:52:51.182
15	\N	INFO	User qqq logged in	2026-06-23 09:52:55.313
16	\N	INFO	User qqq logged out	2026-06-23 09:55:19.45
17	\N	INFO	User admin logged in	2026-06-23 09:55:20.398
18	\N	INFO	User www created by admin	2026-06-23 09:57:03.291
19	\N	INFO	User admin logged out	2026-06-23 09:57:06.942
20	\N	INFO	User www logged in	2026-06-23 09:57:11.602
21	\N	INFO	User www logged out	2026-06-23 11:33:48.851
22	\N	INFO	User admin logged in	2026-06-23 11:33:50.011
23	\N	INFO	User admin logged out	2026-06-23 11:33:55.751
24	\N	INFO	User qqq logged in	2026-06-23 11:34:19.43
25	\N	INFO	User qqq logged in	2026-06-23 11:34:39.215
26	\N	INFO	User admin logged in	2026-06-23 11:35:12.298
27	\N	INFO	Setting room_temp_threshold_on updated to 20.3 by admin	2026-06-23 11:36:56.22
28	\N	INFO	User admin logged out	2026-06-23 11:36:59.047
29	\N	INFO	User qqq logged in	2026-06-23 11:37:03.833
30	\N	INFO	User admin logged in	2026-06-23 11:37:33.501
31	\N	INFO	User admin logged out	2026-06-23 11:37:36.735
32	\N	INFO	User qqq logged in	2026-06-23 11:37:44.881
33	\N	INFO	User admin logged in	2026-06-23 12:06:13.387
34	\N	INFO	Setting room_temp_threshold_off updated to 23 by admin	2026-06-23 12:06:27.468
35	\N	INFO	User admin logged out	2026-06-23 12:06:34.658
36	\N	INFO	User qqq logged in	2026-06-23 12:06:45.633
37	\N	INFO	User qqq logged out	2026-06-23 12:07:08.362
38	\N	INFO	User www logged in	2026-06-23 12:07:12.827
39	\N	INFO	Setting room_temp_threshold_on updated to 22.8 by www	2026-06-23 12:07:23.058
40	\N	INFO	Setting room_temp_target updated to 22.3 by www	2026-06-23 12:13:21.008
41	\N	INFO	Setting room_temp_threshold_on updated to 22.3 by www	2026-06-23 12:13:27.009
42	\N	INFO	User www logged out	2026-06-23 12:13:40.877
43	\N	INFO	User qqq logged in	2026-06-23 12:13:49.878
44	\N	INFO	User qqq logged out	2026-06-23 12:13:56.205
45	\N	INFO	User qqq logged in	2026-06-23 12:14:07.682
46	\N	INFO	User qqq logged out	2026-06-23 12:14:20.878
47	\N	INFO	User www logged in	2026-06-23 12:14:25.825
48	\N	INFO	Setting room_temp_threshold_on updated to 20.3 by www	2026-06-23 12:14:37.846
49	\N	INFO	User www logged out	2026-06-24 06:18:09.281
50	\N	INFO	User admin logged in	2026-06-24 06:18:10.294
\.


--
-- Data for Name: parameters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parameters (id, key, value, description, updated_at) FROM stdin;
3	room_target_temp	22	Целевая температура помещения	2026-06-21 08:50:08.122
4	floor_pump_on_temp	25	Температура включения насоса теплого пола	2026-06-21 08:50:08.124
5	floor_pump_off_temp	20	Температура выключения насоса теплого пола	2026-06-21 08:50:08.127
6	boiler_max_temp	60	Максимальная температура котла	2026-06-21 08:50:08.13
42	boiler_temp_target	55	Целевая температура котла	2026-06-21 09:02:39.351
43	boiler_temp_threshold_on	45	Минимальная температура котла	2026-06-21 09:02:39.351
44	boiler_temp_threshold_off	65	Максимальная температура котла	2026-06-21 09:02:39.351
45	boiler_temp_hysteresis	5	Гистерезис котла	2026-06-21 09:02:39.351
46	accumulator_temp_target	70	Целевая температура теплоаккумулятора	2026-06-21 11:24:57.425
47	accumulator_temp_threshold_on	60	Порог включения ТА	2026-06-21 11:24:57.425
48	accumulator_temp_threshold_off	80	Порог выключения ТА	2026-06-21 11:24:57.425
49	accumulator_temp_hysteresis	5	Гистерезис ТА	2026-06-21 11:24:57.425
51	floor_temp_threshold_on	40	Порог включения тёплых полов	2026-06-21 11:24:57.425
52	floor_temp_threshold_off	60	Порог выключения тёплых полов	2026-06-21 11:24:57.425
53	floor_temp_hysteresis	3	Гистерезис тёплых полов	2026-06-21 11:24:57.425
1	night_start	23:00	Ночной режим начало	2026-06-21 23:46:38.684
2	night_end	07:00	Ночной режим конец	2026-06-21 23:46:43.655
37	room_temp_hysteresis	1	Гистерезис помещения	2026-06-21 23:47:10.17
50	floor_temp_target	50	Целевая температура тёплых полов	2026-06-23 09:53:02.468
36	room_temp_threshold_off	23	Порог выключения отопления	2026-06-23 12:06:27.457
34	room_temp_target	22.3	Целевая температура помещения	2026-06-23 12:13:21.002
35	room_temp_threshold_on	20.3	Порог включения отопления	2026-06-23 12:14:37.837
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, description) FROM stdin;
1	ADMIN	ADMIN role
2	OPERATOR	OPERATOR role
3	VIEWER	VIEWER role
\.


--
-- Data for Name: telemetry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telemetry (id, device_id, parameter, value, "timestamp") FROM stdin;
1	1	room_temp	23.2	2026-06-14 09:02:57.252
2	1	room_temp	23.4	2026-06-14 09:17:57.252
3	1	room_temp	22.7	2026-06-14 09:32:57.252
4	1	room_temp	23.1	2026-06-14 09:47:57.252
5	1	room_temp	22.5	2026-06-14 10:02:57.252
6	1	room_temp	22.8	2026-06-14 10:17:57.252
7	1	room_temp	23.0	2026-06-14 10:32:57.252
8	1	room_temp	22.6	2026-06-14 10:47:57.252
9	1	room_temp	22.5	2026-06-14 11:02:57.252
10	1	room_temp	22.6	2026-06-14 11:17:57.252
11	1	room_temp	22.1	2026-06-14 11:32:57.252
12	1	room_temp	22.2	2026-06-14 11:47:57.252
13	1	room_temp	22.1	2026-06-14 12:02:57.252
14	1	room_temp	21.8	2026-06-14 12:17:57.252
15	1	room_temp	22.4	2026-06-14 12:32:57.252
16	1	room_temp	22.1	2026-06-14 12:47:57.252
17	1	room_temp	21.5	2026-06-14 13:02:57.252
18	1	room_temp	21.4	2026-06-14 13:17:57.252
19	1	room_temp	21.7	2026-06-14 13:32:57.252
20	1	room_temp	21.9	2026-06-14 13:47:57.252
21	1	room_temp	21.3	2026-06-14 14:02:57.252
22	1	room_temp	21.4	2026-06-14 14:17:57.252
23	1	room_temp	21.2	2026-06-14 14:32:57.252
24	1	room_temp	21.2	2026-06-14 14:47:57.252
25	1	room_temp	20.8	2026-06-14 15:02:57.252
26	1	room_temp	21.3	2026-06-14 15:17:57.252
27	1	room_temp	21.2	2026-06-14 15:32:57.252
28	1	room_temp	21.3	2026-06-14 15:47:57.252
29	1	room_temp	20.5	2026-06-14 16:02:57.252
30	1	room_temp	20.7	2026-06-14 16:17:57.252
31	1	room_temp	20.8	2026-06-14 16:32:57.252
32	1	room_temp	20.5	2026-06-14 16:47:57.252
33	1	room_temp	20.8	2026-06-14 17:02:57.252
34	1	room_temp	20.8	2026-06-14 17:17:57.252
35	1	room_temp	20.4	2026-06-14 17:32:57.252
36	1	room_temp	20.6	2026-06-14 17:47:57.252
37	1	room_temp	20.9	2026-06-14 18:02:57.252
38	1	room_temp	20.4	2026-06-14 18:17:57.252
39	1	room_temp	20.8	2026-06-14 18:32:57.252
40	1	room_temp	20.2	2026-06-14 18:47:57.252
41	1	room_temp	20.6	2026-06-14 19:02:57.252
42	1	room_temp	20.2	2026-06-14 19:17:57.252
43	1	room_temp	20.8	2026-06-14 19:32:57.252
44	1	room_temp	20.2	2026-06-14 19:47:57.252
45	1	room_temp	20.9	2026-06-14 20:02:57.252
46	1	room_temp	20.5	2026-06-14 20:17:57.252
47	1	room_temp	20.3	2026-06-14 20:32:57.252
48	1	room_temp	21.0	2026-06-14 20:47:57.252
49	1	room_temp	20.8	2026-06-14 21:02:57.252
50	1	room_temp	20.9	2026-06-14 21:17:57.252
51	1	room_temp	21.0	2026-06-14 21:32:57.252
52	1	room_temp	20.9	2026-06-14 21:47:57.252
53	1	room_temp	21.1	2026-06-14 22:02:57.252
54	1	room_temp	20.9	2026-06-14 22:17:57.252
55	1	room_temp	21.1	2026-06-14 22:32:57.252
56	1	room_temp	21.5	2026-06-14 22:47:57.252
57	1	room_temp	21.6	2026-06-14 23:02:57.252
58	1	room_temp	21.4	2026-06-14 23:17:57.252
59	1	room_temp	21.4	2026-06-14 23:32:57.252
60	1	room_temp	21.8	2026-06-14 23:47:57.252
61	1	room_temp	21.8	2026-06-15 00:02:57.252
62	1	room_temp	21.8	2026-06-15 00:17:57.252
63	1	room_temp	21.7	2026-06-15 00:32:57.252
64	1	room_temp	21.8	2026-06-15 00:47:57.252
65	1	room_temp	22.1	2026-06-15 01:02:57.252
66	1	room_temp	22.1	2026-06-15 01:17:57.252
67	1	room_temp	22.2	2026-06-15 01:32:57.252
68	1	room_temp	22.4	2026-06-15 01:47:57.252
69	1	room_temp	22.4	2026-06-15 02:02:57.252
70	1	room_temp	23.1	2026-06-15 02:17:57.252
71	1	room_temp	23.0	2026-06-15 02:32:57.252
72	1	room_temp	22.5	2026-06-15 02:47:57.252
73	1	room_temp	23.4	2026-06-15 03:02:57.252
74	1	room_temp	23.0	2026-06-15 03:17:57.252
75	1	room_temp	22.7	2026-06-15 03:32:57.252
76	1	room_temp	23.1	2026-06-15 03:47:57.252
77	1	room_temp	22.9	2026-06-15 04:02:57.252
78	1	room_temp	23.5	2026-06-15 04:17:57.252
79	1	room_temp	23.5	2026-06-15 04:32:57.252
80	1	room_temp	23.0	2026-06-15 04:47:57.252
81	1	room_temp	23.5	2026-06-15 05:02:57.252
82	1	room_temp	23.2	2026-06-15 05:17:57.252
83	1	room_temp	23.4	2026-06-15 05:32:57.252
84	1	room_temp	23.6	2026-06-15 05:47:57.252
85	1	room_temp	23.6	2026-06-15 06:02:57.252
86	1	room_temp	23.5	2026-06-15 06:17:57.252
87	1	room_temp	23.7	2026-06-15 06:32:57.252
88	1	room_temp	23.4	2026-06-15 06:47:57.252
89	1	room_temp	23.7	2026-06-15 07:02:57.252
90	1	room_temp	23.3	2026-06-15 07:17:57.252
91	1	room_temp	23.4	2026-06-15 07:32:57.252
92	1	room_temp	23.6	2026-06-15 07:47:57.252
93	1	room_temp	23.6	2026-06-15 08:02:57.252
94	1	room_temp	22.9	2026-06-15 08:17:57.252
95	1	room_temp	23.5	2026-06-15 08:32:57.252
96	1	room_temp	23.3	2026-06-15 08:47:57.252
97	1	room_temp	23.4	2026-06-15 09:02:57.252
98	1	room_temp	22.7	2026-06-15 09:17:57.252
99	1	room_temp	23.2	2026-06-15 09:32:57.252
100	1	room_temp	23.0	2026-06-15 09:47:57.252
101	1	room_temp	22.8	2026-06-15 10:02:57.252
102	1	room_temp	23.0	2026-06-15 10:17:57.252
103	1	room_temp	22.8	2026-06-15 10:32:57.252
104	1	room_temp	22.8	2026-06-15 10:47:57.252
105	1	room_temp	22.5	2026-06-15 11:02:57.252
106	1	room_temp	22.1	2026-06-15 11:17:57.252
107	1	room_temp	22.0	2026-06-15 11:32:57.252
108	1	room_temp	22.3	2026-06-15 11:47:57.252
109	1	room_temp	22.1	2026-06-15 12:02:57.252
110	1	room_temp	21.9	2026-06-15 12:17:57.252
111	1	room_temp	21.6	2026-06-15 12:32:57.252
112	1	room_temp	22.0	2026-06-15 12:47:57.252
113	1	room_temp	21.4	2026-06-15 13:02:57.252
114	1	room_temp	21.8	2026-06-15 13:17:57.252
115	1	room_temp	21.9	2026-06-15 13:32:57.252
116	1	room_temp	21.6	2026-06-15 13:47:57.252
117	1	room_temp	21.4	2026-06-15 14:02:57.252
118	1	room_temp	21.0	2026-06-15 14:17:57.252
119	1	room_temp	21.1	2026-06-15 14:32:57.252
120	1	room_temp	21.6	2026-06-15 14:47:57.252
121	1	room_temp	20.6	2026-06-15 15:02:57.252
122	1	room_temp	20.8	2026-06-15 15:17:57.252
123	1	room_temp	21.3	2026-06-15 15:32:57.252
124	1	room_temp	21.2	2026-06-15 15:47:57.252
125	1	room_temp	20.9	2026-06-15 16:02:57.252
126	1	room_temp	20.5	2026-06-15 16:17:57.252
127	1	room_temp	21.0	2026-06-15 16:32:57.252
128	1	room_temp	20.5	2026-06-15 16:47:57.252
129	1	room_temp	20.2	2026-06-15 17:02:57.252
130	1	room_temp	20.2	2026-06-15 17:17:57.252
131	1	room_temp	20.2	2026-06-15 17:32:57.252
132	1	room_temp	20.2	2026-06-15 17:47:57.252
133	1	room_temp	20.8	2026-06-15 18:02:57.252
134	1	room_temp	20.5	2026-06-15 18:17:57.252
135	1	room_temp	20.7	2026-06-15 18:32:57.252
136	1	room_temp	20.8	2026-06-15 18:47:57.252
137	1	room_temp	20.8	2026-06-15 19:02:57.252
138	1	room_temp	20.5	2026-06-15 19:17:57.252
139	1	room_temp	20.9	2026-06-15 19:32:57.252
140	1	room_temp	20.9	2026-06-15 19:47:57.252
141	1	room_temp	20.8	2026-06-15 20:02:57.252
142	1	room_temp	20.9	2026-06-15 20:17:57.252
143	1	room_temp	20.5	2026-06-15 20:32:57.252
144	1	room_temp	20.6	2026-06-15 20:47:57.252
145	1	room_temp	21.1	2026-06-15 21:02:57.252
146	1	room_temp	20.9	2026-06-15 21:17:57.252
147	1	room_temp	21.2	2026-06-15 21:32:57.252
148	1	room_temp	20.9	2026-06-15 21:47:57.252
149	1	room_temp	21.1	2026-06-15 22:02:57.252
150	1	room_temp	21.5	2026-06-15 22:17:57.252
151	1	room_temp	21.2	2026-06-15 22:32:57.252
152	1	room_temp	21.0	2026-06-15 22:47:57.252
153	1	room_temp	21.9	2026-06-15 23:02:57.252
154	1	room_temp	21.9	2026-06-15 23:17:57.252
155	1	room_temp	22.0	2026-06-15 23:32:57.252
156	1	room_temp	21.3	2026-06-15 23:47:57.252
157	1	room_temp	22.3	2026-06-16 00:02:57.252
158	1	room_temp	22.2	2026-06-16 00:17:57.252
159	1	room_temp	22.0	2026-06-16 00:32:57.252
160	1	room_temp	21.8	2026-06-16 00:47:57.252
161	1	room_temp	22.1	2026-06-16 01:02:57.252
162	1	room_temp	22.2	2026-06-16 01:17:57.252
163	1	room_temp	22.5	2026-06-16 01:32:57.252
164	1	room_temp	22.8	2026-06-16 01:47:57.252
165	1	room_temp	22.8	2026-06-16 02:02:57.252
166	1	room_temp	22.8	2026-06-16 02:17:57.252
167	1	room_temp	22.7	2026-06-16 02:32:57.252
168	1	room_temp	22.5	2026-06-16 02:47:57.252
169	1	room_temp	22.9	2026-06-16 03:02:57.252
170	1	room_temp	23.1	2026-06-16 03:17:57.252
171	1	room_temp	23.0	2026-06-16 03:32:57.252
172	1	room_temp	23.1	2026-06-16 03:47:57.252
173	1	room_temp	23.2	2026-06-16 04:02:57.252
174	1	room_temp	22.9	2026-06-16 04:17:57.252
175	1	room_temp	23.1	2026-06-16 04:32:57.252
176	1	room_temp	23.0	2026-06-16 04:47:57.252
177	1	room_temp	23.4	2026-06-16 05:02:57.252
178	1	room_temp	23.6	2026-06-16 05:17:57.252
179	1	room_temp	23.3	2026-06-16 05:32:57.252
180	1	room_temp	23.2	2026-06-16 05:47:57.252
181	1	room_temp	23.6	2026-06-16 06:02:57.252
182	1	room_temp	23.5	2026-06-16 06:17:57.252
183	1	room_temp	23.4	2026-06-16 06:32:57.252
184	1	room_temp	23.2	2026-06-16 06:47:57.252
185	1	room_temp	23.5	2026-06-16 07:02:57.252
186	1	room_temp	23.0	2026-06-16 07:17:57.252
187	1	room_temp	23.7	2026-06-16 07:32:57.252
188	1	room_temp	23.1	2026-06-16 07:47:57.252
189	1	room_temp	23.2	2026-06-16 08:02:57.252
190	1	room_temp	23.2	2026-06-16 08:17:57.252
191	1	room_temp	23.0	2026-06-16 08:32:57.252
192	1	room_temp	23.2	2026-06-16 08:47:57.252
193	1	room_temp	22.7	2026-06-16 09:02:57.252
194	1	room_temp	23.4	2026-06-16 09:17:57.252
195	1	room_temp	22.8	2026-06-16 09:32:57.252
196	1	room_temp	22.9	2026-06-16 09:47:57.252
197	1	room_temp	22.5	2026-06-16 10:02:57.252
198	1	room_temp	22.5	2026-06-16 10:17:57.252
199	1	room_temp	22.6	2026-06-16 10:32:57.252
200	1	room_temp	22.5	2026-06-16 10:47:57.252
201	1	room_temp	22.0	2026-06-16 11:02:57.252
202	1	room_temp	22.4	2026-06-16 11:17:57.252
203	1	room_temp	22.4	2026-06-16 11:32:57.252
204	1	room_temp	22.1	2026-06-16 11:47:57.252
205	1	room_temp	21.9	2026-06-16 12:02:57.252
206	1	room_temp	21.7	2026-06-16 12:17:57.252
207	1	room_temp	22.3	2026-06-16 12:32:57.252
208	1	room_temp	22.3	2026-06-16 12:47:57.252
209	1	room_temp	21.7	2026-06-16 13:02:57.252
210	1	room_temp	21.6	2026-06-16 13:17:57.252
211	1	room_temp	21.3	2026-06-16 13:32:57.252
212	1	room_temp	21.3	2026-06-16 13:47:57.252
213	1	room_temp	21.3	2026-06-16 14:02:57.252
214	1	room_temp	20.9	2026-06-16 14:17:57.252
215	1	room_temp	21.3	2026-06-16 14:32:57.252
216	1	room_temp	21.1	2026-06-16 14:47:57.252
217	1	room_temp	20.7	2026-06-16 15:02:57.252
218	1	room_temp	21.3	2026-06-16 15:17:57.252
219	1	room_temp	21.1	2026-06-16 15:32:57.252
220	1	room_temp	21.1	2026-06-16 15:47:57.252
221	1	room_temp	20.6	2026-06-16 16:02:57.252
222	1	room_temp	20.4	2026-06-16 16:17:57.252
223	1	room_temp	20.5	2026-06-16 16:32:57.252
224	1	room_temp	20.7	2026-06-16 16:47:57.252
225	1	room_temp	20.8	2026-06-16 17:02:57.252
226	1	room_temp	20.9	2026-06-16 17:17:57.252
227	1	room_temp	20.8	2026-06-16 17:32:57.252
228	1	room_temp	20.5	2026-06-16 17:47:57.252
229	1	room_temp	20.7	2026-06-16 18:02:57.252
230	1	room_temp	20.9	2026-06-16 18:17:57.252
231	1	room_temp	20.1	2026-06-16 18:32:57.252
232	1	room_temp	20.3	2026-06-16 18:47:57.252
233	1	room_temp	20.9	2026-06-16 19:02:57.252
234	1	room_temp	20.3	2026-06-16 19:17:57.252
235	1	room_temp	20.8	2026-06-16 19:32:57.252
236	1	room_temp	20.5	2026-06-16 19:47:57.252
237	1	room_temp	20.3	2026-06-16 20:02:57.252
238	1	room_temp	20.4	2026-06-16 20:17:57.252
239	1	room_temp	20.7	2026-06-16 20:32:57.252
240	1	room_temp	21.0	2026-06-16 20:47:57.252
241	1	room_temp	20.7	2026-06-16 21:02:57.252
242	1	room_temp	21.2	2026-06-16 21:17:57.252
243	1	room_temp	20.7	2026-06-16 21:32:57.252
244	1	room_temp	20.5	2026-06-16 21:47:57.252
245	1	room_temp	21.1	2026-06-16 22:02:57.252
246	1	room_temp	21.4	2026-06-16 22:17:57.252
247	1	room_temp	21.2	2026-06-16 22:32:57.252
248	1	room_temp	21.3	2026-06-16 22:47:57.252
249	1	room_temp	21.8	2026-06-16 23:02:57.252
250	1	room_temp	21.7	2026-06-16 23:17:57.252
251	1	room_temp	21.8	2026-06-16 23:32:57.252
252	1	room_temp	21.5	2026-06-16 23:47:57.252
253	1	room_temp	21.6	2026-06-17 00:02:57.252
254	1	room_temp	22.1	2026-06-17 00:17:57.252
255	1	room_temp	21.9	2026-06-17 00:32:57.252
256	1	room_temp	22.3	2026-06-17 00:47:57.252
257	1	room_temp	22.4	2026-06-17 01:02:57.252
258	1	room_temp	22.6	2026-06-17 01:17:57.252
259	1	room_temp	22.6	2026-06-17 01:32:57.252
260	1	room_temp	22.7	2026-06-17 01:47:57.252
261	1	room_temp	22.6	2026-06-17 02:02:57.252
262	1	room_temp	22.6	2026-06-17 02:17:57.252
263	1	room_temp	22.5	2026-06-17 02:32:57.252
264	1	room_temp	22.8	2026-06-17 02:47:57.252
265	1	room_temp	23.3	2026-06-17 03:02:57.252
266	1	room_temp	22.8	2026-06-17 03:17:57.252
267	1	room_temp	23.4	2026-06-17 03:32:57.252
268	1	room_temp	22.9	2026-06-17 03:47:57.252
269	1	room_temp	23.6	2026-06-17 04:02:57.252
270	1	room_temp	23.2	2026-06-17 04:17:57.252
271	1	room_temp	23.5	2026-06-17 04:32:57.252
272	1	room_temp	23.4	2026-06-17 04:47:57.252
273	1	room_temp	23.5	2026-06-17 05:02:57.252
274	1	room_temp	23.1	2026-06-17 05:17:57.252
275	1	room_temp	23.3	2026-06-17 05:32:57.252
276	1	room_temp	23.1	2026-06-17 05:47:57.252
277	1	room_temp	23.5	2026-06-17 06:02:57.252
278	1	room_temp	23.6	2026-06-17 06:17:57.252
279	1	room_temp	23.2	2026-06-17 06:32:57.252
280	1	room_temp	23.5	2026-06-17 06:47:57.252
281	1	room_temp	23.7	2026-06-17 07:02:57.252
282	1	room_temp	23.6	2026-06-17 07:17:57.252
283	1	room_temp	23.1	2026-06-17 07:32:57.252
284	1	room_temp	23.6	2026-06-17 07:47:57.252
285	1	room_temp	23.6	2026-06-17 08:02:57.252
286	1	room_temp	23.0	2026-06-17 08:17:57.252
287	1	room_temp	23.4	2026-06-17 08:32:57.252
288	1	room_temp	23.2	2026-06-17 08:47:57.252
289	1	room_temp	23.3	2026-06-17 09:02:57.252
290	1	room_temp	22.9	2026-06-17 09:17:57.252
291	1	room_temp	23.4	2026-06-17 09:32:57.252
292	1	room_temp	22.7	2026-06-17 09:47:57.252
293	1	room_temp	22.4	2026-06-17 10:02:57.252
294	1	room_temp	22.4	2026-06-17 10:17:57.252
295	1	room_temp	22.6	2026-06-17 10:32:57.252
296	1	room_temp	22.4	2026-06-17 10:47:57.252
297	1	room_temp	22.6	2026-06-17 11:02:57.252
298	1	room_temp	22.3	2026-06-17 11:17:57.252
299	1	room_temp	22.5	2026-06-17 11:32:57.252
300	1	room_temp	22.1	2026-06-17 11:47:57.252
301	1	room_temp	22.0	2026-06-17 12:02:57.252
302	1	room_temp	22.3	2026-06-17 12:17:57.252
303	1	room_temp	21.8	2026-06-17 12:32:57.252
304	1	room_temp	21.6	2026-06-17 12:47:57.252
305	1	room_temp	21.5	2026-06-17 13:02:57.252
306	1	room_temp	21.6	2026-06-17 13:17:57.252
307	1	room_temp	21.5	2026-06-17 13:32:57.252
308	1	room_temp	21.7	2026-06-17 13:47:57.252
309	1	room_temp	21.3	2026-06-17 14:02:57.252
310	1	room_temp	21.2	2026-06-17 14:17:57.252
311	1	room_temp	21.1	2026-06-17 14:32:57.252
312	1	room_temp	21.1	2026-06-17 14:47:57.252
313	1	room_temp	20.9	2026-06-17 15:02:57.252
314	1	room_temp	21.1	2026-06-17 15:17:57.252
315	1	room_temp	21.2	2026-06-17 15:32:57.252
316	1	room_temp	20.9	2026-06-17 15:47:57.252
317	1	room_temp	21.0	2026-06-17 16:02:57.252
318	1	room_temp	20.6	2026-06-17 16:17:57.252
319	1	room_temp	20.7	2026-06-17 16:32:57.252
320	1	room_temp	20.9	2026-06-17 16:47:57.252
321	1	room_temp	20.7	2026-06-17 17:02:57.252
322	1	room_temp	20.9	2026-06-17 17:17:57.252
323	1	room_temp	20.4	2026-06-17 17:32:57.252
324	1	room_temp	20.3	2026-06-17 17:47:57.252
325	1	room_temp	20.3	2026-06-17 18:02:57.252
326	1	room_temp	20.3	2026-06-17 18:17:57.252
327	1	room_temp	20.7	2026-06-17 18:32:57.252
328	1	room_temp	20.6	2026-06-17 18:47:57.252
329	1	room_temp	20.5	2026-06-17 19:02:57.252
330	1	room_temp	20.7	2026-06-17 19:17:57.252
331	1	room_temp	20.6	2026-06-17 19:32:57.252
332	1	room_temp	20.3	2026-06-17 19:47:57.252
333	1	room_temp	21.1	2026-06-17 20:02:57.252
334	1	room_temp	21.0	2026-06-17 20:17:57.252
335	1	room_temp	20.9	2026-06-17 20:32:57.252
336	1	room_temp	20.7	2026-06-17 20:47:57.252
337	1	room_temp	20.6	2026-06-17 21:02:57.252
338	1	room_temp	21.1	2026-06-17 21:17:57.252
339	1	room_temp	21.3	2026-06-17 21:32:57.252
340	1	room_temp	21.1	2026-06-17 21:47:57.252
341	1	room_temp	21.4	2026-06-17 22:02:57.252
342	1	room_temp	21.4	2026-06-17 22:17:57.252
343	1	room_temp	21.0	2026-06-17 22:32:57.252
344	1	room_temp	21.1	2026-06-17 22:47:57.252
345	1	room_temp	21.4	2026-06-17 23:02:57.252
346	1	room_temp	21.9	2026-06-17 23:17:57.252
347	1	room_temp	21.9	2026-06-17 23:32:57.252
348	1	room_temp	21.8	2026-06-17 23:47:57.252
349	1	room_temp	22.3	2026-06-18 00:02:57.252
350	1	room_temp	21.8	2026-06-18 00:17:57.252
351	1	room_temp	22.4	2026-06-18 00:32:57.252
352	1	room_temp	22.2	2026-06-18 00:47:57.252
353	1	room_temp	22.4	2026-06-18 01:02:57.252
354	1	room_temp	22.5	2026-06-18 01:17:57.252
355	1	room_temp	22.3	2026-06-18 01:32:57.252
356	1	room_temp	22.7	2026-06-18 01:47:57.252
357	1	room_temp	22.5	2026-06-18 02:02:57.252
358	1	room_temp	22.4	2026-06-18 02:17:57.252
359	1	room_temp	23.0	2026-06-18 02:32:57.252
360	1	room_temp	22.7	2026-06-18 02:47:57.252
361	1	room_temp	22.7	2026-06-18 03:02:57.252
362	1	room_temp	23.2	2026-06-18 03:17:57.252
363	1	room_temp	23.4	2026-06-18 03:32:57.252
364	1	room_temp	22.7	2026-06-18 03:47:57.252
365	1	room_temp	23.2	2026-06-18 04:02:57.252
366	1	room_temp	23.5	2026-06-18 04:17:57.252
367	1	room_temp	23.4	2026-06-18 04:32:57.252
368	1	room_temp	23.6	2026-06-18 04:47:57.252
369	1	room_temp	23.7	2026-06-18 05:02:57.252
370	1	room_temp	23.8	2026-06-18 05:17:57.252
371	1	room_temp	23.4	2026-06-18 05:32:57.252
372	1	room_temp	23.5	2026-06-18 05:47:57.252
373	1	room_temp	23.9	2026-06-18 06:02:57.252
374	1	room_temp	23.5	2026-06-18 06:17:57.252
375	1	room_temp	23.2	2026-06-18 06:32:57.252
376	1	room_temp	23.7	2026-06-18 06:47:57.252
377	1	room_temp	23.2	2026-06-18 07:02:57.252
378	1	room_temp	23.5	2026-06-18 07:17:57.252
379	1	room_temp	23.3	2026-06-18 07:32:57.252
380	1	room_temp	23.4	2026-06-18 07:47:57.252
381	1	room_temp	23.0	2026-06-18 08:02:57.252
382	1	room_temp	23.4	2026-06-18 08:17:57.252
383	1	room_temp	23.4	2026-06-18 08:32:57.252
384	1	room_temp	23.4	2026-06-18 08:47:57.252
385	1	room_temp	22.8	2026-06-18 09:02:57.252
386	1	room_temp	22.7	2026-06-18 09:17:57.252
387	1	room_temp	22.7	2026-06-18 09:32:57.252
388	1	room_temp	22.9	2026-06-18 09:47:57.252
389	1	room_temp	22.5	2026-06-18 10:02:57.252
390	1	room_temp	22.7	2026-06-18 10:17:57.252
391	1	room_temp	22.8	2026-06-18 10:32:57.252
392	1	room_temp	23.0	2026-06-18 10:47:57.252
393	1	room_temp	22.1	2026-06-18 11:02:57.252
394	1	room_temp	22.3	2026-06-18 11:17:57.252
395	1	room_temp	22.0	2026-06-18 11:32:57.252
396	1	room_temp	22.2	2026-06-18 11:47:57.252
397	1	room_temp	21.8	2026-06-18 12:02:57.252
398	1	room_temp	22.4	2026-06-18 12:17:57.252
399	1	room_temp	21.8	2026-06-18 12:32:57.252
400	1	room_temp	22.2	2026-06-18 12:47:57.252
401	1	room_temp	21.4	2026-06-18 13:02:57.252
402	1	room_temp	21.8	2026-06-18 13:17:57.252
403	1	room_temp	21.8	2026-06-18 13:32:57.252
404	1	room_temp	21.6	2026-06-18 13:47:57.252
405	1	room_temp	21.0	2026-06-18 14:02:57.252
406	1	room_temp	21.3	2026-06-18 14:17:57.252
407	1	room_temp	21.6	2026-06-18 14:32:57.252
408	1	room_temp	21.2	2026-06-18 14:47:57.252
409	1	room_temp	21.1	2026-06-18 15:02:57.252
410	1	room_temp	20.9	2026-06-18 15:17:57.252
411	1	room_temp	21.0	2026-06-18 15:32:57.252
412	1	room_temp	21.1	2026-06-18 15:47:57.252
413	1	room_temp	20.9	2026-06-18 16:02:57.252
414	1	room_temp	20.9	2026-06-18 16:17:57.252
415	1	room_temp	20.5	2026-06-18 16:32:57.252
416	1	room_temp	20.7	2026-06-18 16:47:57.252
417	1	room_temp	20.4	2026-06-18 17:02:57.252
418	1	room_temp	20.3	2026-06-18 17:17:57.252
419	1	room_temp	20.8	2026-06-18 17:32:57.252
420	1	room_temp	20.7	2026-06-18 17:47:57.252
421	1	room_temp	20.6	2026-06-18 18:02:57.252
422	1	room_temp	20.3	2026-06-18 18:17:57.252
423	1	room_temp	20.6	2026-06-18 18:32:57.252
424	1	room_temp	20.4	2026-06-18 18:47:57.252
425	1	room_temp	20.5	2026-06-18 19:02:57.252
426	1	room_temp	20.9	2026-06-18 19:17:57.252
427	1	room_temp	20.4	2026-06-18 19:32:57.252
428	1	room_temp	20.4	2026-06-18 19:47:57.252
429	1	room_temp	20.5	2026-06-18 20:02:57.252
430	1	room_temp	20.8	2026-06-18 20:17:57.252
431	1	room_temp	20.7	2026-06-18 20:32:57.252
432	1	room_temp	20.7	2026-06-18 20:47:57.252
433	1	room_temp	20.8	2026-06-18 21:02:57.252
434	1	room_temp	20.6	2026-06-18 21:17:57.252
435	1	room_temp	21.0	2026-06-18 21:32:57.252
436	1	room_temp	20.9	2026-06-18 21:47:57.252
437	1	room_temp	20.9	2026-06-18 22:02:57.252
438	1	room_temp	21.0	2026-06-18 22:17:57.252
439	1	room_temp	21.5	2026-06-18 22:32:57.252
440	1	room_temp	20.9	2026-06-18 22:47:57.252
441	1	room_temp	21.4	2026-06-18 23:02:57.252
442	1	room_temp	21.2	2026-06-18 23:17:57.252
443	1	room_temp	22.0	2026-06-18 23:32:57.252
444	1	room_temp	21.3	2026-06-18 23:47:57.252
445	1	room_temp	21.9	2026-06-19 00:02:57.252
446	1	room_temp	21.7	2026-06-19 00:17:57.252
447	1	room_temp	21.8	2026-06-19 00:32:57.252
448	1	room_temp	21.7	2026-06-19 00:47:57.252
449	1	room_temp	22.1	2026-06-19 01:02:57.252
450	1	room_temp	22.1	2026-06-19 01:17:57.252
451	1	room_temp	22.5	2026-06-19 01:32:57.252
452	1	room_temp	22.3	2026-06-19 01:47:57.252
453	1	room_temp	22.5	2026-06-19 02:02:57.252
454	1	room_temp	23.1	2026-06-19 02:17:57.252
455	1	room_temp	23.1	2026-06-19 02:32:57.252
456	1	room_temp	22.9	2026-06-19 02:47:57.252
457	1	room_temp	22.9	2026-06-19 03:02:57.252
458	1	room_temp	23.2	2026-06-19 03:17:57.252
459	1	room_temp	22.7	2026-06-19 03:32:57.252
460	1	room_temp	22.7	2026-06-19 03:47:57.252
461	1	room_temp	22.9	2026-06-19 04:02:57.252
462	1	room_temp	23.0	2026-06-19 04:17:57.252
463	1	room_temp	22.9	2026-06-19 04:32:57.252
464	1	room_temp	23.6	2026-06-19 04:47:57.252
465	1	room_temp	23.1	2026-06-19 05:02:57.252
466	1	room_temp	23.1	2026-06-19 05:17:57.252
467	1	room_temp	23.1	2026-06-19 05:32:57.252
468	1	room_temp	23.3	2026-06-19 05:47:57.252
469	1	room_temp	23.2	2026-06-19 06:02:57.252
470	1	room_temp	23.3	2026-06-19 06:17:57.252
471	1	room_temp	23.1	2026-06-19 06:32:57.252
472	1	room_temp	23.9	2026-06-19 06:47:57.252
473	1	room_temp	23.3	2026-06-19 07:02:57.252
474	1	room_temp	23.5	2026-06-19 07:17:57.252
475	1	room_temp	23.8	2026-06-19 07:32:57.252
476	1	room_temp	23.4	2026-06-19 07:47:57.252
477	1	room_temp	23.7	2026-06-19 08:02:57.252
478	1	room_temp	23.1	2026-06-19 08:17:57.252
479	1	room_temp	23.0	2026-06-19 08:32:57.252
480	1	room_temp	22.9	2026-06-19 08:47:57.252
481	1	room_temp	23.1	2026-06-19 09:02:57.252
482	1	room_temp	22.8	2026-06-19 09:17:57.252
483	1	room_temp	23.4	2026-06-19 09:32:57.252
484	1	room_temp	22.7	2026-06-19 09:47:57.252
485	1	room_temp	22.6	2026-06-19 10:02:57.252
486	1	room_temp	22.5	2026-06-19 10:17:57.252
487	1	room_temp	22.8	2026-06-19 10:32:57.252
488	1	room_temp	22.7	2026-06-19 10:47:57.252
489	1	room_temp	22.1	2026-06-19 11:02:57.252
490	1	room_temp	22.8	2026-06-19 11:17:57.252
491	1	room_temp	22.4	2026-06-19 11:32:57.252
492	1	room_temp	22.3	2026-06-19 11:47:57.252
493	1	room_temp	22.1	2026-06-19 12:02:57.252
494	1	room_temp	22.0	2026-06-19 12:17:57.252
495	1	room_temp	22.1	2026-06-19 12:32:57.252
496	1	room_temp	21.6	2026-06-19 12:47:57.252
497	1	room_temp	21.3	2026-06-19 13:02:57.252
498	1	room_temp	21.5	2026-06-19 13:17:57.252
499	1	room_temp	21.5	2026-06-19 13:32:57.252
500	1	room_temp	21.5	2026-06-19 13:47:57.252
501	1	room_temp	21.4	2026-06-19 14:02:57.252
502	1	room_temp	20.9	2026-06-19 14:17:57.252
503	1	room_temp	20.9	2026-06-19 14:32:57.252
504	1	room_temp	21.4	2026-06-19 14:47:57.252
505	1	room_temp	20.7	2026-06-19 15:02:57.252
506	1	room_temp	21.1	2026-06-19 15:17:57.252
507	1	room_temp	21.3	2026-06-19 15:32:57.252
508	1	room_temp	20.7	2026-06-19 15:47:57.252
509	1	room_temp	20.9	2026-06-19 16:02:57.252
510	1	room_temp	21.0	2026-06-19 16:17:57.252
511	1	room_temp	20.3	2026-06-19 16:32:57.252
512	1	room_temp	21.0	2026-06-19 16:47:57.252
513	1	room_temp	20.3	2026-06-19 17:02:57.252
514	1	room_temp	20.9	2026-06-19 17:17:57.252
515	1	room_temp	20.5	2026-06-19 17:32:57.252
516	1	room_temp	20.8	2026-06-19 17:47:57.252
517	1	room_temp	20.4	2026-06-19 18:02:57.252
518	1	room_temp	20.8	2026-06-19 18:17:57.252
519	1	room_temp	20.8	2026-06-19 18:32:57.252
520	1	room_temp	20.3	2026-06-19 18:47:57.252
521	1	room_temp	20.5	2026-06-19 19:02:57.252
522	1	room_temp	20.7	2026-06-19 19:17:57.252
523	1	room_temp	20.3	2026-06-19 19:32:57.252
524	1	room_temp	20.2	2026-06-19 19:47:57.252
525	1	room_temp	20.4	2026-06-19 20:02:57.252
526	1	room_temp	20.7	2026-06-19 20:17:57.252
527	1	room_temp	21.0	2026-06-19 20:32:57.252
528	1	room_temp	20.5	2026-06-19 20:47:57.252
529	1	room_temp	20.8	2026-06-19 21:02:57.252
530	1	room_temp	21.3	2026-06-19 21:17:57.252
531	1	room_temp	21.0	2026-06-19 21:32:57.252
532	1	room_temp	21.1	2026-06-19 21:47:57.252
533	1	room_temp	21.4	2026-06-19 22:02:57.252
534	1	room_temp	21.6	2026-06-19 22:17:57.252
535	1	room_temp	21.2	2026-06-19 22:32:57.252
536	1	room_temp	21.3	2026-06-19 22:47:57.252
537	1	room_temp	21.6	2026-06-19 23:02:57.252
538	1	room_temp	21.3	2026-06-19 23:17:57.252
539	1	room_temp	21.2	2026-06-19 23:32:57.252
540	1	room_temp	22.0	2026-06-19 23:47:57.252
541	1	room_temp	22.1	2026-06-20 00:02:57.252
542	1	room_temp	21.6	2026-06-20 00:17:57.252
543	1	room_temp	21.9	2026-06-20 00:32:57.252
544	1	room_temp	21.7	2026-06-20 00:47:57.252
545	1	room_temp	22.6	2026-06-20 01:02:57.252
546	1	room_temp	22.2	2026-06-20 01:17:57.252
547	1	room_temp	22.3	2026-06-20 01:32:57.252
548	1	room_temp	22.7	2026-06-20 01:47:57.252
549	1	room_temp	22.8	2026-06-20 02:02:57.252
550	1	room_temp	22.9	2026-06-20 02:17:57.252
551	1	room_temp	22.7	2026-06-20 02:32:57.252
552	1	room_temp	22.6	2026-06-20 02:47:57.252
553	1	room_temp	23.0	2026-06-20 03:02:57.252
554	1	room_temp	22.9	2026-06-20 03:17:57.252
555	1	room_temp	23.2	2026-06-20 03:32:57.252
556	1	room_temp	23.4	2026-06-20 03:47:57.252
557	1	room_temp	23.2	2026-06-20 04:02:57.252
558	1	room_temp	23.2	2026-06-20 04:17:57.252
559	1	room_temp	23.5	2026-06-20 04:32:57.252
560	1	room_temp	23.5	2026-06-20 04:47:57.252
561	1	room_temp	23.5	2026-06-20 05:02:57.252
562	1	room_temp	23.3	2026-06-20 05:17:57.252
563	1	room_temp	23.8	2026-06-20 05:32:57.252
564	1	room_temp	23.4	2026-06-20 05:47:57.252
565	1	room_temp	23.4	2026-06-20 06:02:57.252
566	1	room_temp	23.2	2026-06-20 06:17:57.252
567	1	room_temp	23.1	2026-06-20 06:32:57.252
568	1	room_temp	23.7	2026-06-20 06:47:57.252
569	1	room_temp	23.6	2026-06-20 07:02:57.252
570	1	room_temp	23.5	2026-06-20 07:17:57.252
571	1	room_temp	23.5	2026-06-20 07:32:57.252
572	1	room_temp	23.5	2026-06-20 07:47:57.252
573	1	room_temp	23.1	2026-06-20 08:02:57.252
574	1	room_temp	23.1	2026-06-20 08:17:57.252
575	1	room_temp	23.7	2026-06-20 08:32:57.252
576	1	room_temp	23.6	2026-06-20 08:47:57.252
577	1	room_temp	23.0	2026-06-20 09:02:57.252
578	1	room_temp	22.7	2026-06-20 09:17:57.252
579	1	room_temp	22.9	2026-06-20 09:32:57.252
580	1	room_temp	23.1	2026-06-20 09:47:57.252
581	1	room_temp	22.8	2026-06-20 10:02:57.252
582	1	room_temp	22.5	2026-06-20 10:17:57.252
583	1	room_temp	22.8	2026-06-20 10:32:57.252
584	1	room_temp	23.1	2026-06-20 10:47:57.252
585	1	room_temp	22.3	2026-06-20 11:02:57.252
586	1	room_temp	22.8	2026-06-20 11:17:57.252
587	1	room_temp	22.4	2026-06-20 11:32:57.252
588	1	room_temp	22.0	2026-06-20 11:47:57.252
589	1	room_temp	21.9	2026-06-20 12:02:57.252
590	1	room_temp	21.8	2026-06-20 12:17:57.252
591	1	room_temp	22.1	2026-06-20 12:32:57.252
592	1	room_temp	22.0	2026-06-20 12:47:57.252
593	1	room_temp	21.8	2026-06-20 13:02:57.252
594	1	room_temp	21.4	2026-06-20 13:17:57.252
595	1	room_temp	21.6	2026-06-20 13:32:57.252
596	1	room_temp	21.6	2026-06-20 13:47:57.252
597	1	room_temp	21.1	2026-06-20 14:02:57.252
598	1	room_temp	21.4	2026-06-20 14:17:57.252
599	1	room_temp	20.9	2026-06-20 14:32:57.252
600	1	room_temp	21.6	2026-06-20 14:47:57.252
601	1	room_temp	20.9	2026-06-20 15:02:57.252
602	1	room_temp	21.0	2026-06-20 15:17:57.252
603	1	room_temp	20.8	2026-06-20 15:32:57.252
604	1	room_temp	20.8	2026-06-20 15:47:57.252
605	1	room_temp	20.9	2026-06-20 16:02:57.252
606	1	room_temp	20.9	2026-06-20 16:17:57.252
607	1	room_temp	20.9	2026-06-20 16:32:57.252
608	1	room_temp	20.4	2026-06-20 16:47:57.252
609	1	room_temp	20.9	2026-06-20 17:02:57.252
610	1	room_temp	20.7	2026-06-20 17:17:57.252
611	1	room_temp	20.5	2026-06-20 17:32:57.252
612	1	room_temp	20.8	2026-06-20 17:47:57.252
613	1	room_temp	20.6	2026-06-20 18:02:57.252
614	1	room_temp	20.5	2026-06-20 18:17:57.252
615	1	room_temp	20.7	2026-06-20 18:32:57.252
616	1	room_temp	20.4	2026-06-20 18:47:57.252
617	1	room_temp	20.7	2026-06-20 19:02:57.252
618	1	room_temp	20.5	2026-06-20 19:17:57.252
619	1	room_temp	20.5	2026-06-20 19:32:57.252
620	1	room_temp	20.3	2026-06-20 19:47:57.252
621	1	room_temp	20.9	2026-06-20 20:02:57.252
622	1	room_temp	20.7	2026-06-20 20:17:57.252
623	1	room_temp	20.8	2026-06-20 20:32:57.252
624	1	room_temp	20.5	2026-06-20 20:47:57.252
625	1	room_temp	21.0	2026-06-20 21:02:57.252
626	1	room_temp	21.3	2026-06-20 21:17:57.252
627	1	room_temp	20.9	2026-06-20 21:32:57.252
628	1	room_temp	20.7	2026-06-20 21:47:57.252
629	1	room_temp	21.2	2026-06-20 22:02:57.252
630	1	room_temp	21.5	2026-06-20 22:17:57.252
631	1	room_temp	21.0	2026-06-20 22:32:57.252
632	1	room_temp	21.3	2026-06-20 22:47:57.252
633	1	room_temp	21.4	2026-06-20 23:02:57.252
634	1	room_temp	22.0	2026-06-20 23:17:57.252
635	1	room_temp	22.0	2026-06-20 23:32:57.252
636	1	room_temp	21.8	2026-06-20 23:47:57.252
637	1	room_temp	22.1	2026-06-21 00:02:57.252
638	1	room_temp	21.8	2026-06-21 00:17:57.252
639	1	room_temp	22.4	2026-06-21 00:32:57.252
640	1	room_temp	21.7	2026-06-21 00:47:57.252
641	1	room_temp	22.5	2026-06-21 01:02:57.252
642	1	room_temp	22.3	2026-06-21 01:17:57.252
643	1	room_temp	22.3	2026-06-21 01:32:57.252
644	1	room_temp	22.7	2026-06-21 01:47:57.252
645	1	room_temp	23.1	2026-06-21 02:02:57.252
646	1	room_temp	22.4	2026-06-21 02:17:57.252
647	1	room_temp	22.7	2026-06-21 02:32:57.252
648	1	room_temp	22.6	2026-06-21 02:47:57.252
649	1	room_temp	22.8	2026-06-21 03:02:57.252
650	1	room_temp	22.7	2026-06-21 03:17:57.252
651	1	room_temp	23.4	2026-06-21 03:32:57.252
652	1	room_temp	22.7	2026-06-21 03:47:57.252
653	1	room_temp	22.9	2026-06-21 04:02:57.252
654	1	room_temp	23.0	2026-06-21 04:17:57.252
655	1	room_temp	23.2	2026-06-21 04:32:57.252
656	1	room_temp	23.2	2026-06-21 04:47:57.252
657	1	room_temp	23.3	2026-06-21 05:02:57.252
658	1	room_temp	23.6	2026-06-21 05:17:57.252
659	1	room_temp	23.7	2026-06-21 05:32:57.252
660	1	room_temp	23.7	2026-06-21 05:47:57.252
661	1	room_temp	23.8	2026-06-21 06:02:57.252
662	1	room_temp	23.3	2026-06-21 06:17:57.252
663	1	room_temp	23.5	2026-06-21 06:32:57.252
664	1	room_temp	23.9	2026-06-21 06:47:57.252
665	1	room_temp	23.8	2026-06-21 07:02:57.252
666	1	room_temp	23.4	2026-06-21 07:17:57.252
667	1	room_temp	23.2	2026-06-21 07:32:57.252
668	1	room_temp	23.4	2026-06-21 07:47:57.252
669	1	room_temp	22.9	2026-06-21 08:02:57.252
670	1	room_temp	23.2	2026-06-21 08:17:57.252
671	1	room_temp	23.0	2026-06-21 08:32:57.252
672	1	room_temp	23.2	2026-06-21 08:47:57.252
673	1	room_temp	23.2	2026-06-21 09:02:57.252
674	1	outdoor_temp	0.2	2026-06-14 09:03:08.237
675	1	outdoor_temp	1.1	2026-06-14 09:18:08.237
676	1	outdoor_temp	1.5	2026-06-14 09:33:08.237
677	1	outdoor_temp	1.3	2026-06-14 09:48:08.237
678	1	outdoor_temp	-0.2	2026-06-14 10:03:08.237
679	1	outdoor_temp	0.3	2026-06-14 10:18:08.237
680	1	outdoor_temp	-1.1	2026-06-14 10:33:08.237
681	1	outdoor_temp	0.4	2026-06-14 10:48:08.237
682	1	outdoor_temp	-0.8	2026-06-14 11:03:08.237
683	1	outdoor_temp	-0.7	2026-06-14 11:18:08.237
684	1	outdoor_temp	-1.4	2026-06-14 11:33:08.237
685	1	outdoor_temp	-2.1	2026-06-14 11:48:08.237
686	1	outdoor_temp	-3.7	2026-06-14 12:03:08.237
687	1	outdoor_temp	-2.1	2026-06-14 12:18:08.237
688	1	outdoor_temp	-3.2	2026-06-14 12:33:08.237
689	1	outdoor_temp	-2.4	2026-06-14 12:48:08.237
690	1	outdoor_temp	-4.2	2026-06-14 13:03:08.237
691	1	outdoor_temp	-5.2	2026-06-14 13:18:08.237
692	1	outdoor_temp	-4.1	2026-06-14 13:33:08.237
693	1	outdoor_temp	-3.7	2026-06-14 13:48:08.237
694	1	outdoor_temp	-5.8	2026-06-14 14:03:08.237
695	1	outdoor_temp	-6.1	2026-06-14 14:18:08.237
696	1	outdoor_temp	-4.9	2026-06-14 14:33:08.237
697	1	outdoor_temp	-5.8	2026-06-14 14:48:08.237
698	1	outdoor_temp	-7.0	2026-06-14 15:03:08.237
699	1	outdoor_temp	-5.6	2026-06-14 15:18:08.237
700	1	outdoor_temp	-6.5	2026-06-14 15:33:08.237
701	1	outdoor_temp	-5.6	2026-06-14 15:48:08.237
702	1	outdoor_temp	-8.3	2026-06-14 16:03:08.237
703	1	outdoor_temp	-7.0	2026-06-14 16:18:08.237
704	1	outdoor_temp	-7.5	2026-06-14 16:33:08.237
705	1	outdoor_temp	-7.2	2026-06-14 16:48:08.237
706	1	outdoor_temp	-8.4	2026-06-14 17:03:08.237
707	1	outdoor_temp	-7.2	2026-06-14 17:18:08.237
708	1	outdoor_temp	-7.9	2026-06-14 17:33:08.237
709	1	outdoor_temp	-8.3	2026-06-14 17:48:08.237
710	1	outdoor_temp	-8.3	2026-06-14 18:03:08.237
711	1	outdoor_temp	-7.2	2026-06-14 18:18:08.237
712	1	outdoor_temp	-7.9	2026-06-14 18:33:08.237
713	1	outdoor_temp	-7.5	2026-06-14 18:48:08.237
714	1	outdoor_temp	-8.6	2026-06-14 19:03:08.237
715	1	outdoor_temp	-8.7	2026-06-14 19:18:08.237
716	1	outdoor_temp	-7.7	2026-06-14 19:33:08.237
717	1	outdoor_temp	-8.7	2026-06-14 19:48:08.237
718	1	outdoor_temp	-7.0	2026-06-14 20:03:08.237
719	1	outdoor_temp	-8.2	2026-06-14 20:18:08.237
720	1	outdoor_temp	-7.5	2026-06-14 20:33:08.237
721	1	outdoor_temp	-6.4	2026-06-14 20:48:08.237
722	1	outdoor_temp	-7.5	2026-06-14 21:03:08.237
723	1	outdoor_temp	-5.6	2026-06-14 21:18:08.237
724	1	outdoor_temp	-6.9	2026-06-14 21:33:08.237
725	1	outdoor_temp	-5.9	2026-06-14 21:48:08.237
726	1	outdoor_temp	-6.5	2026-06-14 22:03:08.237
727	1	outdoor_temp	-5.0	2026-06-14 22:18:08.237
728	1	outdoor_temp	-4.8	2026-06-14 22:33:08.237
729	1	outdoor_temp	-6.4	2026-06-14 22:48:08.237
730	1	outdoor_temp	-3.5	2026-06-14 23:03:08.237
731	1	outdoor_temp	-4.8	2026-06-14 23:18:08.237
732	1	outdoor_temp	-4.0	2026-06-14 23:33:08.237
733	1	outdoor_temp	-4.7	2026-06-14 23:48:08.237
734	1	outdoor_temp	-2.3	2026-06-15 00:03:08.237
735	1	outdoor_temp	-2.6	2026-06-15 00:18:08.237
736	1	outdoor_temp	-2.4	2026-06-15 00:33:08.237
737	1	outdoor_temp	-3.5	2026-06-15 00:48:08.237
738	1	outdoor_temp	-2.4	2026-06-15 01:03:08.237
739	1	outdoor_temp	-0.8	2026-06-15 01:18:08.237
740	1	outdoor_temp	-1.2	2026-06-15 01:33:08.237
741	1	outdoor_temp	-1.1	2026-06-15 01:48:08.237
742	1	outdoor_temp	-0.9	2026-06-15 02:03:08.237
743	1	outdoor_temp	-1.1	2026-06-15 02:18:08.237
744	1	outdoor_temp	-0.6	2026-06-15 02:33:08.237
745	1	outdoor_temp	-1.2	2026-06-15 02:48:08.237
746	1	outdoor_temp	0.8	2026-06-15 03:03:08.237
747	1	outdoor_temp	0.4	2026-06-15 03:18:08.237
748	1	outdoor_temp	-0.4	2026-06-15 03:33:08.237
749	1	outdoor_temp	0.1	2026-06-15 03:48:08.237
750	1	outdoor_temp	1.5	2026-06-15 04:03:08.237
751	1	outdoor_temp	1.1	2026-06-15 04:18:08.237
752	1	outdoor_temp	1.6	2026-06-15 04:33:08.237
753	1	outdoor_temp	1.2	2026-06-15 04:48:08.237
754	1	outdoor_temp	1.7	2026-06-15 05:03:08.237
755	1	outdoor_temp	1.2	2026-06-15 05:18:08.237
756	1	outdoor_temp	2.2	2026-06-15 05:33:08.237
757	1	outdoor_temp	2.4	2026-06-15 05:48:08.237
758	1	outdoor_temp	2.9	2026-06-15 06:03:08.237
759	1	outdoor_temp	2.5	2026-06-15 06:18:08.237
760	1	outdoor_temp	2.0	2026-06-15 06:33:08.237
761	1	outdoor_temp	2.0	2026-06-15 06:48:08.237
762	1	outdoor_temp	1.1	2026-06-15 07:03:08.237
763	1	outdoor_temp	1.9	2026-06-15 07:18:08.237
764	1	outdoor_temp	2.1	2026-06-15 07:33:08.237
765	1	outdoor_temp	2.2	2026-06-15 07:48:08.237
766	1	outdoor_temp	2.3	2026-06-15 08:03:08.237
767	1	outdoor_temp	1.8	2026-06-15 08:18:08.237
768	1	outdoor_temp	1.4	2026-06-15 08:33:08.237
769	1	outdoor_temp	2.1	2026-06-15 08:48:08.237
770	1	outdoor_temp	-0.2	2026-06-15 09:03:08.237
771	1	outdoor_temp	0.0	2026-06-15 09:18:08.237
772	1	outdoor_temp	-0.2	2026-06-15 09:33:08.237
773	1	outdoor_temp	0.5	2026-06-15 09:48:08.237
774	1	outdoor_temp	-0.9	2026-06-15 10:03:08.237
775	1	outdoor_temp	0.0	2026-06-15 10:18:08.237
776	1	outdoor_temp	-1.2	2026-06-15 10:33:08.237
777	1	outdoor_temp	0.0	2026-06-15 10:48:08.237
778	1	outdoor_temp	-1.5	2026-06-15 11:03:08.237
779	1	outdoor_temp	-0.9	2026-06-15 11:18:08.237
780	1	outdoor_temp	-2.4	2026-06-15 11:33:08.237
781	1	outdoor_temp	-1.8	2026-06-15 11:48:08.237
782	1	outdoor_temp	-2.2	2026-06-15 12:03:08.237
783	1	outdoor_temp	-3.2	2026-06-15 12:18:08.237
784	1	outdoor_temp	-3.4	2026-06-15 12:33:08.237
785	1	outdoor_temp	-2.1	2026-06-15 12:48:08.237
786	1	outdoor_temp	-3.7	2026-06-15 13:03:08.237
787	1	outdoor_temp	-4.9	2026-06-15 13:18:08.237
788	1	outdoor_temp	-4.9	2026-06-15 13:33:08.237
789	1	outdoor_temp	-3.3	2026-06-15 13:48:08.237
790	1	outdoor_temp	-5.8	2026-06-15 14:03:08.237
791	1	outdoor_temp	-5.3	2026-06-15 14:18:08.237
792	1	outdoor_temp	-5.8	2026-06-15 14:33:08.237
793	1	outdoor_temp	-5.8	2026-06-15 14:48:08.237
794	1	outdoor_temp	-7.3	2026-06-15 15:03:08.237
795	1	outdoor_temp	-6.1	2026-06-15 15:18:08.237
796	1	outdoor_temp	-5.9	2026-06-15 15:33:08.237
797	1	outdoor_temp	-6.9	2026-06-15 15:48:08.237
798	1	outdoor_temp	-6.3	2026-06-15 16:03:08.237
799	1	outdoor_temp	-7.3	2026-06-15 16:18:08.237
800	1	outdoor_temp	-6.6	2026-06-15 16:33:08.237
801	1	outdoor_temp	-7.7	2026-06-15 16:48:08.237
802	1	outdoor_temp	-8.2	2026-06-15 17:03:08.237
803	1	outdoor_temp	-7.1	2026-06-15 17:18:08.237
804	1	outdoor_temp	-7.7	2026-06-15 17:33:08.237
805	1	outdoor_temp	-8.6	2026-06-15 17:48:08.237
806	1	outdoor_temp	-7.8	2026-06-15 18:03:08.237
807	1	outdoor_temp	-7.1	2026-06-15 18:18:08.237
808	1	outdoor_temp	-7.1	2026-06-15 18:33:08.237
809	1	outdoor_temp	-7.3	2026-06-15 18:48:08.237
810	1	outdoor_temp	-7.5	2026-06-15 19:03:08.237
811	1	outdoor_temp	-7.9	2026-06-15 19:18:08.237
812	1	outdoor_temp	-8.8	2026-06-15 19:33:08.237
813	1	outdoor_temp	-7.1	2026-06-15 19:48:08.237
814	1	outdoor_temp	-8.3	2026-06-15 20:03:08.237
815	1	outdoor_temp	-6.9	2026-06-15 20:18:08.237
816	1	outdoor_temp	-7.7	2026-06-15 20:33:08.237
817	1	outdoor_temp	-7.5	2026-06-15 20:48:08.237
818	1	outdoor_temp	-6.0	2026-06-15 21:03:08.237
819	1	outdoor_temp	-7.5	2026-06-15 21:18:08.237
820	1	outdoor_temp	-6.6	2026-06-15 21:33:08.237
821	1	outdoor_temp	-7.2	2026-06-15 21:48:08.237
822	1	outdoor_temp	-4.6	2026-06-15 22:03:08.237
823	1	outdoor_temp	-5.0	2026-06-15 22:18:08.237
824	1	outdoor_temp	-4.6	2026-06-15 22:33:08.237
825	1	outdoor_temp	-6.3	2026-06-15 22:48:08.237
826	1	outdoor_temp	-3.3	2026-06-15 23:03:08.237
827	1	outdoor_temp	-5.1	2026-06-15 23:18:08.237
828	1	outdoor_temp	-3.6	2026-06-15 23:33:08.237
829	1	outdoor_temp	-4.6	2026-06-15 23:48:08.237
830	1	outdoor_temp	-2.3	2026-06-16 00:03:08.237
831	1	outdoor_temp	-3.2	2026-06-16 00:18:08.237
832	1	outdoor_temp	-3.8	2026-06-16 00:33:08.237
833	1	outdoor_temp	-2.3	2026-06-16 00:48:08.237
834	1	outdoor_temp	-1.6	2026-06-16 01:03:08.237
835	1	outdoor_temp	-1.8	2026-06-16 01:18:08.237
836	1	outdoor_temp	-1.9	2026-06-16 01:33:08.237
837	1	outdoor_temp	-0.9	2026-06-16 01:48:08.237
838	1	outdoor_temp	-0.6	2026-06-16 02:03:08.237
839	1	outdoor_temp	0.3	2026-06-16 02:18:08.237
840	1	outdoor_temp	0.5	2026-06-16 02:33:08.237
841	1	outdoor_temp	-0.3	2026-06-16 02:48:08.237
842	1	outdoor_temp	0.8	2026-06-16 03:03:08.237
843	1	outdoor_temp	-0.4	2026-06-16 03:18:08.237
844	1	outdoor_temp	0.2	2026-06-16 03:33:08.237
845	1	outdoor_temp	0.3	2026-06-16 03:48:08.237
846	1	outdoor_temp	1.6	2026-06-16 04:03:08.237
847	1	outdoor_temp	0.9	2026-06-16 04:18:08.237
848	1	outdoor_temp	1.0	2026-06-16 04:33:08.237
849	1	outdoor_temp	0.4	2026-06-16 04:48:08.237
850	1	outdoor_temp	1.9	2026-06-16 05:03:08.237
851	1	outdoor_temp	0.8	2026-06-16 05:18:08.237
852	1	outdoor_temp	1.5	2026-06-16 05:33:08.237
853	1	outdoor_temp	2.0	2026-06-16 05:48:08.237
854	1	outdoor_temp	1.5	2026-06-16 06:03:08.237
855	1	outdoor_temp	1.7	2026-06-16 06:18:08.237
856	1	outdoor_temp	1.5	2026-06-16 06:33:08.237
857	1	outdoor_temp	2.0	2026-06-16 06:48:08.237
858	1	outdoor_temp	1.3	2026-06-16 07:03:08.237
859	1	outdoor_temp	1.6	2026-06-16 07:18:08.237
860	1	outdoor_temp	2.0	2026-06-16 07:33:08.237
861	1	outdoor_temp	1.5	2026-06-16 07:48:08.237
862	1	outdoor_temp	0.8	2026-06-16 08:03:08.237
863	1	outdoor_temp	1.8	2026-06-16 08:18:08.237
864	1	outdoor_temp	1.7	2026-06-16 08:33:08.237
865	1	outdoor_temp	1.3	2026-06-16 08:48:08.237
866	1	outdoor_temp	1.2	2026-06-16 09:03:08.237
867	1	outdoor_temp	-0.1	2026-06-16 09:18:08.237
868	1	outdoor_temp	1.3	2026-06-16 09:33:08.237
869	1	outdoor_temp	0.8	2026-06-16 09:48:08.237
870	1	outdoor_temp	-1.1	2026-06-16 10:03:08.237
871	1	outdoor_temp	-1.4	2026-06-16 10:18:08.237
872	1	outdoor_temp	-0.8	2026-06-16 10:33:08.237
873	1	outdoor_temp	-0.4	2026-06-16 10:48:08.237
874	1	outdoor_temp	-1.1	2026-06-16 11:03:08.237
875	1	outdoor_temp	-1.0	2026-06-16 11:18:08.237
876	1	outdoor_temp	-2.4	2026-06-16 11:33:08.237
877	1	outdoor_temp	-2.0	2026-06-16 11:48:08.237
878	1	outdoor_temp	-3.1	2026-06-16 12:03:08.237
879	1	outdoor_temp	-3.5	2026-06-16 12:18:08.237
880	1	outdoor_temp	-2.5	2026-06-16 12:33:08.237
881	1	outdoor_temp	-3.2	2026-06-16 12:48:08.237
882	1	outdoor_temp	-4.8	2026-06-16 13:03:08.237
883	1	outdoor_temp	-5.2	2026-06-16 13:18:08.237
884	1	outdoor_temp	-3.5	2026-06-16 13:33:08.237
885	1	outdoor_temp	-5.3	2026-06-16 13:48:08.237
886	1	outdoor_temp	-5.3	2026-06-16 14:03:08.237
887	1	outdoor_temp	-5.3	2026-06-16 14:18:08.237
888	1	outdoor_temp	-5.8	2026-06-16 14:33:08.237
889	1	outdoor_temp	-5.6	2026-06-16 14:48:08.237
890	1	outdoor_temp	-6.2	2026-06-16 15:03:08.237
891	1	outdoor_temp	-7.1	2026-06-16 15:18:08.237
892	1	outdoor_temp	-6.4	2026-06-16 15:33:08.237
893	1	outdoor_temp	-7.2	2026-06-16 15:48:08.237
894	1	outdoor_temp	-6.4	2026-06-16 16:03:08.237
895	1	outdoor_temp	-6.9	2026-06-16 16:18:08.237
896	1	outdoor_temp	-8.0	2026-06-16 16:33:08.237
897	1	outdoor_temp	-6.4	2026-06-16 16:48:08.237
898	1	outdoor_temp	-8.8	2026-06-16 17:03:08.237
899	1	outdoor_temp	-7.3	2026-06-16 17:18:08.237
900	1	outdoor_temp	-8.8	2026-06-16 17:33:08.237
901	1	outdoor_temp	-7.7	2026-06-16 17:48:08.237
902	1	outdoor_temp	-7.9	2026-06-16 18:03:08.237
903	1	outdoor_temp	-8.3	2026-06-16 18:18:08.237
904	1	outdoor_temp	-7.5	2026-06-16 18:33:08.237
905	1	outdoor_temp	-7.9	2026-06-16 18:48:08.237
906	1	outdoor_temp	-6.8	2026-06-16 19:03:08.237
907	1	outdoor_temp	-7.6	2026-06-16 19:18:08.237
908	1	outdoor_temp	-7.2	2026-06-16 19:33:08.237
909	1	outdoor_temp	-8.5	2026-06-16 19:48:08.237
910	1	outdoor_temp	-7.7	2026-06-16 20:03:08.237
911	1	outdoor_temp	-6.4	2026-06-16 20:18:08.237
912	1	outdoor_temp	-7.4	2026-06-16 20:33:08.237
913	1	outdoor_temp	-8.0	2026-06-16 20:48:08.237
914	1	outdoor_temp	-6.6	2026-06-16 21:03:08.237
915	1	outdoor_temp	-7.2	2026-06-16 21:18:08.237
916	1	outdoor_temp	-7.1	2026-06-16 21:33:08.237
917	1	outdoor_temp	-6.3	2026-06-16 21:48:08.237
918	1	outdoor_temp	-5.1	2026-06-16 22:03:08.237
919	1	outdoor_temp	-5.2	2026-06-16 22:18:08.237
920	1	outdoor_temp	-6.3	2026-06-16 22:33:08.237
921	1	outdoor_temp	-5.4	2026-06-16 22:48:08.237
922	1	outdoor_temp	-3.7	2026-06-16 23:03:08.237
923	1	outdoor_temp	-3.7	2026-06-16 23:18:08.237
924	1	outdoor_temp	-4.9	2026-06-16 23:33:08.237
925	1	outdoor_temp	-3.7	2026-06-16 23:48:08.237
926	1	outdoor_temp	-3.2	2026-06-17 00:03:08.237
927	1	outdoor_temp	-3.5	2026-06-17 00:18:08.237
928	1	outdoor_temp	-3.1	2026-06-17 00:33:08.237
929	1	outdoor_temp	-3.4	2026-06-17 00:48:08.237
930	1	outdoor_temp	-2.6	2026-06-17 01:03:08.237
931	1	outdoor_temp	-2.5	2026-06-17 01:18:08.237
932	1	outdoor_temp	-2.1	2026-06-17 01:33:08.237
933	1	outdoor_temp	-2.3	2026-06-17 01:48:08.237
934	1	outdoor_temp	-1.4	2026-06-17 02:03:08.237
935	1	outdoor_temp	-0.8	2026-06-17 02:18:08.237
936	1	outdoor_temp	-0.6	2026-06-17 02:33:08.237
937	1	outdoor_temp	-0.9	2026-06-17 02:48:08.237
938	1	outdoor_temp	1.0	2026-06-17 03:03:08.237
939	1	outdoor_temp	-0.2	2026-06-17 03:18:08.237
940	1	outdoor_temp	0.5	2026-06-17 03:33:08.237
941	1	outdoor_temp	1.5	2026-06-17 03:48:08.237
942	1	outdoor_temp	0.6	2026-06-17 04:03:08.237
943	1	outdoor_temp	2.3	2026-06-17 04:18:08.237
944	1	outdoor_temp	2.1	2026-06-17 04:33:08.237
945	1	outdoor_temp	1.5	2026-06-17 04:48:08.237
946	1	outdoor_temp	2.6	2026-06-17 05:03:08.237
947	1	outdoor_temp	1.7	2026-06-17 05:18:08.237
948	1	outdoor_temp	1.1	2026-06-17 05:33:08.237
949	1	outdoor_temp	2.0	2026-06-17 05:48:08.237
950	1	outdoor_temp	1.5	2026-06-17 06:03:08.237
951	1	outdoor_temp	2.9	2026-06-17 06:18:08.237
952	1	outdoor_temp	2.7	2026-06-17 06:33:08.237
953	1	outdoor_temp	2.4	2026-06-17 06:48:08.237
954	1	outdoor_temp	1.3	2026-06-17 07:03:08.237
955	1	outdoor_temp	2.6	2026-06-17 07:18:08.237
956	1	outdoor_temp	2.5	2026-06-17 07:33:08.237
957	1	outdoor_temp	2.5	2026-06-17 07:48:08.237
958	1	outdoor_temp	0.6	2026-06-17 08:03:08.237
959	1	outdoor_temp	0.4	2026-06-17 08:18:08.237
960	1	outdoor_temp	2.1	2026-06-17 08:33:08.237
961	1	outdoor_temp	1.2	2026-06-17 08:48:08.237
962	1	outdoor_temp	0.7	2026-06-17 09:03:08.237
963	1	outdoor_temp	0.0	2026-06-17 09:18:08.237
964	1	outdoor_temp	0.8	2026-06-17 09:33:08.237
965	1	outdoor_temp	1.0	2026-06-17 09:48:08.237
966	1	outdoor_temp	0.4	2026-06-17 10:03:08.237
967	1	outdoor_temp	0.4	2026-06-17 10:18:08.237
968	1	outdoor_temp	-1.0	2026-06-17 10:33:08.237
969	1	outdoor_temp	-1.0	2026-06-17 10:48:08.237
970	1	outdoor_temp	-1.6	2026-06-17 11:03:08.237
971	1	outdoor_temp	-1.3	2026-06-17 11:18:08.237
972	1	outdoor_temp	-1.6	2026-06-17 11:33:08.237
973	1	outdoor_temp	-0.7	2026-06-17 11:48:08.237
974	1	outdoor_temp	-3.3	2026-06-17 12:03:08.237
975	1	outdoor_temp	-3.0	2026-06-17 12:18:08.237
976	1	outdoor_temp	-3.2	2026-06-17 12:33:08.237
977	1	outdoor_temp	-2.3	2026-06-17 12:48:08.237
978	1	outdoor_temp	-4.6	2026-06-17 13:03:08.237
979	1	outdoor_temp	-4.1	2026-06-17 13:18:08.237
980	1	outdoor_temp	-4.4	2026-06-17 13:33:08.237
981	1	outdoor_temp	-4.2	2026-06-17 13:48:08.237
982	1	outdoor_temp	-6.1	2026-06-17 14:03:08.237
983	1	outdoor_temp	-6.3	2026-06-17 14:18:08.237
984	1	outdoor_temp	-5.9	2026-06-17 14:33:08.237
985	1	outdoor_temp	-5.8	2026-06-17 14:48:08.237
986	1	outdoor_temp	-7.3	2026-06-17 15:03:08.237
987	1	outdoor_temp	-7.2	2026-06-17 15:18:08.237
988	1	outdoor_temp	-6.5	2026-06-17 15:33:08.237
989	1	outdoor_temp	-6.8	2026-06-17 15:48:08.237
990	1	outdoor_temp	-6.5	2026-06-17 16:03:08.237
991	1	outdoor_temp	-7.5	2026-06-17 16:18:08.237
992	1	outdoor_temp	-6.5	2026-06-17 16:33:08.237
993	1	outdoor_temp	-7.6	2026-06-17 16:48:08.237
994	1	outdoor_temp	-6.9	2026-06-17 17:03:08.237
995	1	outdoor_temp	-7.0	2026-06-17 17:18:08.237
996	1	outdoor_temp	-8.5	2026-06-17 17:33:08.237
997	1	outdoor_temp	-8.3	2026-06-17 17:48:08.237
998	1	outdoor_temp	-8.5	2026-06-17 18:03:08.237
999	1	outdoor_temp	-8.2	2026-06-17 18:18:08.237
1000	1	outdoor_temp	-7.6	2026-06-17 18:33:08.237
1001	1	outdoor_temp	-7.3	2026-06-17 18:48:08.237
1002	1	outdoor_temp	-7.8	2026-06-17 19:03:08.237
1003	1	outdoor_temp	-8.0	2026-06-17 19:18:08.237
1004	1	outdoor_temp	-7.9	2026-06-17 19:33:08.237
1005	1	outdoor_temp	-7.5	2026-06-17 19:48:08.237
1006	1	outdoor_temp	-7.5	2026-06-17 20:03:08.237
1007	1	outdoor_temp	-6.9	2026-06-17 20:18:08.237
1008	1	outdoor_temp	-6.5	2026-06-17 20:33:08.237
1009	1	outdoor_temp	-7.0	2026-06-17 20:48:08.237
1010	1	outdoor_temp	-5.7	2026-06-17 21:03:08.237
1011	1	outdoor_temp	-5.9	2026-06-17 21:18:08.237
1012	1	outdoor_temp	-6.4	2026-06-17 21:33:08.237
1013	1	outdoor_temp	-6.3	2026-06-17 21:48:08.237
1014	1	outdoor_temp	-5.3	2026-06-17 22:03:08.237
1015	1	outdoor_temp	-4.9	2026-06-17 22:18:08.237
1016	1	outdoor_temp	-5.9	2026-06-17 22:33:08.237
1017	1	outdoor_temp	-5.2	2026-06-17 22:48:08.237
1018	1	outdoor_temp	-4.7	2026-06-17 23:03:08.237
1019	1	outdoor_temp	-4.6	2026-06-17 23:18:08.237
1020	1	outdoor_temp	-5.2	2026-06-17 23:33:08.237
1021	1	outdoor_temp	-4.2	2026-06-17 23:48:08.237
1022	1	outdoor_temp	-2.6	2026-06-18 00:03:08.237
1023	1	outdoor_temp	-3.0	2026-06-18 00:18:08.237
1024	1	outdoor_temp	-2.8	2026-06-18 00:33:08.237
1025	1	outdoor_temp	-2.7	2026-06-18 00:48:08.237
1026	1	outdoor_temp	-2.4	2026-06-18 01:03:08.237
1027	1	outdoor_temp	-2.4	2026-06-18 01:18:08.237
1028	1	outdoor_temp	-2.0	2026-06-18 01:33:08.237
1029	1	outdoor_temp	-1.4	2026-06-18 01:48:08.237
1030	1	outdoor_temp	-0.9	2026-06-18 02:03:08.237
1031	1	outdoor_temp	-1.4	2026-06-18 02:18:08.237
1032	1	outdoor_temp	0.4	2026-06-18 02:33:08.237
1033	1	outdoor_temp	-0.3	2026-06-18 02:48:08.237
1034	1	outdoor_temp	0.3	2026-06-18 03:03:08.237
1035	1	outdoor_temp	-0.4	2026-06-18 03:18:08.237
1036	1	outdoor_temp	0.4	2026-06-18 03:33:08.237
1037	1	outdoor_temp	-0.2	2026-06-18 03:48:08.237
1038	1	outdoor_temp	0.4	2026-06-18 04:03:08.237
1039	1	outdoor_temp	1.5	2026-06-18 04:18:08.237
1040	1	outdoor_temp	1.2	2026-06-18 04:33:08.237
1041	1	outdoor_temp	1.2	2026-06-18 04:48:08.237
1042	1	outdoor_temp	2.0	2026-06-18 05:03:08.237
1043	1	outdoor_temp	2.3	2026-06-18 05:18:08.237
1044	1	outdoor_temp	0.9	2026-06-18 05:33:08.237
1045	1	outdoor_temp	1.8	2026-06-18 05:48:08.237
1046	1	outdoor_temp	1.9	2026-06-18 06:03:08.237
1047	1	outdoor_temp	2.4	2026-06-18 06:18:08.237
1048	1	outdoor_temp	1.4	2026-06-18 06:33:08.237
1049	1	outdoor_temp	2.8	2026-06-18 06:48:08.237
1050	1	outdoor_temp	2.4	2026-06-18 07:03:08.237
1051	1	outdoor_temp	2.2	2026-06-18 07:18:08.237
1052	1	outdoor_temp	2.1	2026-06-18 07:33:08.237
1053	1	outdoor_temp	1.3	2026-06-18 07:48:08.237
1054	1	outdoor_temp	0.6	2026-06-18 08:03:08.237
1055	1	outdoor_temp	2.0	2026-06-18 08:18:08.237
1056	1	outdoor_temp	1.2	2026-06-18 08:33:08.237
1057	1	outdoor_temp	1.7	2026-06-18 08:48:08.237
1058	1	outdoor_temp	0.5	2026-06-18 09:03:08.237
1059	1	outdoor_temp	0.7	2026-06-18 09:18:08.237
1060	1	outdoor_temp	1.5	2026-06-18 09:33:08.237
1061	1	outdoor_temp	1.5	2026-06-18 09:48:08.237
1062	1	outdoor_temp	-0.9	2026-06-18 10:03:08.237
1063	1	outdoor_temp	-1.2	2026-06-18 10:18:08.237
1064	1	outdoor_temp	-0.8	2026-06-18 10:33:08.237
1065	1	outdoor_temp	-1.2	2026-06-18 10:48:08.237
1066	1	outdoor_temp	-2.6	2026-06-18 11:03:08.237
1067	1	outdoor_temp	-2.5	2026-06-18 11:18:08.237
1068	1	outdoor_temp	-2.0	2026-06-18 11:33:08.237
1069	1	outdoor_temp	-1.7	2026-06-18 11:48:08.237
1070	1	outdoor_temp	-2.5	2026-06-18 12:03:08.237
1071	1	outdoor_temp	-2.8	2026-06-18 12:18:08.237
1072	1	outdoor_temp	-3.5	2026-06-18 12:33:08.237
1073	1	outdoor_temp	-3.9	2026-06-18 12:48:08.237
1074	1	outdoor_temp	-4.5	2026-06-18 13:03:08.237
1075	1	outdoor_temp	-3.5	2026-06-18 13:18:08.237
1076	1	outdoor_temp	-4.0	2026-06-18 13:33:08.237
1077	1	outdoor_temp	-4.4	2026-06-18 13:48:08.237
1078	1	outdoor_temp	-5.4	2026-06-18 14:03:08.237
1079	1	outdoor_temp	-5.8	2026-06-18 14:18:08.237
1080	1	outdoor_temp	-5.1	2026-06-18 14:33:08.237
1081	1	outdoor_temp	-6.1	2026-06-18 14:48:08.237
1082	1	outdoor_temp	-7.4	2026-06-18 15:03:08.237
1083	1	outdoor_temp	-6.4	2026-06-18 15:18:08.237
1084	1	outdoor_temp	-5.6	2026-06-18 15:33:08.237
1085	1	outdoor_temp	-6.4	2026-06-18 15:48:08.237
1086	1	outdoor_temp	-7.5	2026-06-18 16:03:08.237
1087	1	outdoor_temp	-7.3	2026-06-18 16:18:08.237
1088	1	outdoor_temp	-6.6	2026-06-18 16:33:08.237
1089	1	outdoor_temp	-6.5	2026-06-18 16:48:08.237
1090	1	outdoor_temp	-8.6	2026-06-18 17:03:08.237
1091	1	outdoor_temp	-8.6	2026-06-18 17:18:08.237
1092	1	outdoor_temp	-7.3	2026-06-18 17:33:08.237
1093	1	outdoor_temp	-6.9	2026-06-18 17:48:08.237
1094	1	outdoor_temp	-8.1	2026-06-18 18:03:08.237
1095	1	outdoor_temp	-8.7	2026-06-18 18:18:08.237
1096	1	outdoor_temp	-8.6	2026-06-18 18:33:08.237
1097	1	outdoor_temp	-8.2	2026-06-18 18:48:08.237
1098	1	outdoor_temp	-6.8	2026-06-18 19:03:08.237
1099	1	outdoor_temp	-7.3	2026-06-18 19:18:08.237
1100	1	outdoor_temp	-8.6	2026-06-18 19:33:08.237
1101	1	outdoor_temp	-8.0	2026-06-18 19:48:08.237
1102	1	outdoor_temp	-8.1	2026-06-18 20:03:08.237
1103	1	outdoor_temp	-6.8	2026-06-18 20:18:08.237
1104	1	outdoor_temp	-6.3	2026-06-18 20:33:08.237
1105	1	outdoor_temp	-7.3	2026-06-18 20:48:08.237
1106	1	outdoor_temp	-6.4	2026-06-18 21:03:08.237
1107	1	outdoor_temp	-5.9	2026-06-18 21:18:08.237
1108	1	outdoor_temp	-5.9	2026-06-18 21:33:08.237
1109	1	outdoor_temp	-7.2	2026-06-18 21:48:08.237
1110	1	outdoor_temp	-6.0	2026-06-18 22:03:08.237
1111	1	outdoor_temp	-5.2	2026-06-18 22:18:08.237
1112	1	outdoor_temp	-5.1	2026-06-18 22:33:08.237
1113	1	outdoor_temp	-4.6	2026-06-18 22:48:08.237
1114	1	outdoor_temp	-4.7	2026-06-18 23:03:08.237
1115	1	outdoor_temp	-4.7	2026-06-18 23:18:08.237
1116	1	outdoor_temp	-3.5	2026-06-18 23:33:08.237
1117	1	outdoor_temp	-5.1	2026-06-18 23:48:08.237
1118	1	outdoor_temp	-3.2	2026-06-19 00:03:08.237
1119	1	outdoor_temp	-2.9	2026-06-19 00:18:08.237
1120	1	outdoor_temp	-2.0	2026-06-19 00:33:08.237
1121	1	outdoor_temp	-2.3	2026-06-19 00:48:08.237
1122	1	outdoor_temp	-2.6	2026-06-19 01:03:08.237
1123	1	outdoor_temp	-2.0	2026-06-19 01:18:08.237
1124	1	outdoor_temp	-2.4	2026-06-19 01:33:08.237
1125	1	outdoor_temp	-2.6	2026-06-19 01:48:08.237
1126	1	outdoor_temp	-0.8	2026-06-19 02:03:08.237
1127	1	outdoor_temp	-1.1	2026-06-19 02:18:08.237
1128	1	outdoor_temp	-1.1	2026-06-19 02:33:08.237
1129	1	outdoor_temp	-0.1	2026-06-19 02:48:08.237
1130	1	outdoor_temp	0.2	2026-06-19 03:03:08.237
1131	1	outdoor_temp	0.1	2026-06-19 03:18:08.237
1132	1	outdoor_temp	1.4	2026-06-19 03:33:08.237
1133	1	outdoor_temp	-0.2	2026-06-19 03:48:08.237
1134	1	outdoor_temp	0.5	2026-06-19 04:03:08.237
1135	1	outdoor_temp	1.0	2026-06-19 04:18:08.237
1136	1	outdoor_temp	1.0	2026-06-19 04:33:08.237
1137	1	outdoor_temp	1.9	2026-06-19 04:48:08.237
1138	1	outdoor_temp	1.0	2026-06-19 05:03:08.237
1139	1	outdoor_temp	1.0	2026-06-19 05:18:08.237
1140	1	outdoor_temp	2.0	2026-06-19 05:33:08.237
1141	1	outdoor_temp	1.3	2026-06-19 05:48:08.237
1142	1	outdoor_temp	2.9	2026-06-19 06:03:08.237
1143	1	outdoor_temp	2.1	2026-06-19 06:18:08.237
1144	1	outdoor_temp	2.0	2026-06-19 06:33:08.237
1145	1	outdoor_temp	2.6	2026-06-19 06:48:08.237
1146	1	outdoor_temp	1.2	2026-06-19 07:03:08.237
1147	1	outdoor_temp	1.7	2026-06-19 07:18:08.237
1148	1	outdoor_temp	1.5	2026-06-19 07:33:08.237
1149	1	outdoor_temp	1.5	2026-06-19 07:48:08.237
1150	1	outdoor_temp	1.1	2026-06-19 08:03:08.237
1151	1	outdoor_temp	1.4	2026-06-19 08:18:08.237
1152	1	outdoor_temp	0.9	2026-06-19 08:33:08.237
1153	1	outdoor_temp	2.2	2026-06-19 08:48:08.237
1154	1	outdoor_temp	0.9	2026-06-19 09:03:08.237
1155	1	outdoor_temp	-0.4	2026-06-19 09:18:08.237
1156	1	outdoor_temp	0.3	2026-06-19 09:33:08.237
1157	1	outdoor_temp	0.8	2026-06-19 09:48:08.237
1158	1	outdoor_temp	0.2	2026-06-19 10:03:08.237
1159	1	outdoor_temp	-1.3	2026-06-19 10:18:08.237
1160	1	outdoor_temp	0.3	2026-06-19 10:33:08.237
1161	1	outdoor_temp	0.2	2026-06-19 10:48:08.237
1162	1	outdoor_temp	-1.6	2026-06-19 11:03:08.237
1163	1	outdoor_temp	-1.3	2026-06-19 11:18:08.237
1164	1	outdoor_temp	-0.9	2026-06-19 11:33:08.237
1165	1	outdoor_temp	-1.3	2026-06-19 11:48:08.237
1166	1	outdoor_temp	-2.2	2026-06-19 12:03:08.237
1167	1	outdoor_temp	-3.7	2026-06-19 12:18:08.237
1168	1	outdoor_temp	-2.1	2026-06-19 12:33:08.237
1169	1	outdoor_temp	-3.0	2026-06-19 12:48:08.237
1170	1	outdoor_temp	-4.1	2026-06-19 13:03:08.237
1171	1	outdoor_temp	-3.5	2026-06-19 13:18:08.237
1172	1	outdoor_temp	-3.3	2026-06-19 13:33:08.237
1173	1	outdoor_temp	-4.1	2026-06-19 13:48:08.237
1174	1	outdoor_temp	-6.4	2026-06-19 14:03:08.237
1175	1	outdoor_temp	-5.8	2026-06-19 14:18:08.237
1176	1	outdoor_temp	-4.5	2026-06-19 14:33:08.237
1177	1	outdoor_temp	-5.9	2026-06-19 14:48:08.237
1178	1	outdoor_temp	-7.1	2026-06-19 15:03:08.237
1179	1	outdoor_temp	-5.6	2026-06-19 15:18:08.237
1180	1	outdoor_temp	-7.2	2026-06-19 15:33:08.237
1181	1	outdoor_temp	-6.5	2026-06-19 15:48:08.237
1182	1	outdoor_temp	-8.1	2026-06-19 16:03:08.237
1183	1	outdoor_temp	-7.7	2026-06-19 16:18:08.237
1184	1	outdoor_temp	-7.0	2026-06-19 16:33:08.237
1185	1	outdoor_temp	-7.6	2026-06-19 16:48:08.237
1186	1	outdoor_temp	-7.3	2026-06-19 17:03:08.237
1187	1	outdoor_temp	-7.4	2026-06-19 17:18:08.237
1188	1	outdoor_temp	-7.0	2026-06-19 17:33:08.237
1189	1	outdoor_temp	-8.0	2026-06-19 17:48:08.237
1190	1	outdoor_temp	-8.5	2026-06-19 18:03:08.237
1191	1	outdoor_temp	-8.8	2026-06-19 18:18:08.237
1192	1	outdoor_temp	-8.9	2026-06-19 18:33:08.237
1193	1	outdoor_temp	-7.8	2026-06-19 18:48:08.237
1194	1	outdoor_temp	-8.6	2026-06-19 19:03:08.237
1195	1	outdoor_temp	-7.3	2026-06-19 19:18:08.237
1196	1	outdoor_temp	-8.2	2026-06-19 19:33:08.237
1197	1	outdoor_temp	-6.9	2026-06-19 19:48:08.237
1198	1	outdoor_temp	-8.1	2026-06-19 20:03:08.237
1199	1	outdoor_temp	-7.6	2026-06-19 20:18:08.237
1200	1	outdoor_temp	-6.4	2026-06-19 20:33:08.237
1201	1	outdoor_temp	-7.8	2026-06-19 20:48:08.237
1202	1	outdoor_temp	-5.9	2026-06-19 21:03:08.237
1203	1	outdoor_temp	-6.7	2026-06-19 21:18:08.237
1204	1	outdoor_temp	-5.7	2026-06-19 21:33:08.237
1205	1	outdoor_temp	-6.7	2026-06-19 21:48:08.237
1206	1	outdoor_temp	-6.2	2026-06-19 22:03:08.237
1207	1	outdoor_temp	-4.9	2026-06-19 22:18:08.237
1208	1	outdoor_temp	-5.3	2026-06-19 22:33:08.237
1209	1	outdoor_temp	-4.9	2026-06-19 22:48:08.237
1210	1	outdoor_temp	-3.8	2026-06-19 23:03:08.237
1211	1	outdoor_temp	-3.5	2026-06-19 23:18:08.237
1212	1	outdoor_temp	-4.1	2026-06-19 23:33:08.237
1213	1	outdoor_temp	-4.0	2026-06-19 23:48:08.237
1214	1	outdoor_temp	-2.9	2026-06-20 00:03:08.237
1215	1	outdoor_temp	-2.6	2026-06-20 00:18:08.237
1216	1	outdoor_temp	-3.5	2026-06-20 00:33:08.237
1217	1	outdoor_temp	-3.3	2026-06-20 00:48:08.237
1218	1	outdoor_temp	-1.3	2026-06-20 01:03:08.237
1219	1	outdoor_temp	-1.0	2026-06-20 01:18:08.237
1220	1	outdoor_temp	-1.7	2026-06-20 01:33:08.237
1221	1	outdoor_temp	-1.1	2026-06-20 01:48:08.237
1222	1	outdoor_temp	-0.4	2026-06-20 02:03:08.237
1223	1	outdoor_temp	0.0	2026-06-20 02:18:08.237
1224	1	outdoor_temp	-1.3	2026-06-20 02:33:08.237
1225	1	outdoor_temp	0.2	2026-06-20 02:48:08.237
1226	1	outdoor_temp	-0.4	2026-06-20 03:03:08.237
1227	1	outdoor_temp	1.3	2026-06-20 03:18:08.237
1228	1	outdoor_temp	1.3	2026-06-20 03:33:08.237
1229	1	outdoor_temp	0.3	2026-06-20 03:48:08.237
1230	1	outdoor_temp	1.3	2026-06-20 04:03:08.237
1231	1	outdoor_temp	2.3	2026-06-20 04:18:08.237
1232	1	outdoor_temp	1.2	2026-06-20 04:33:08.237
1233	1	outdoor_temp	0.6	2026-06-20 04:48:08.237
1234	1	outdoor_temp	1.5	2026-06-20 05:03:08.237
1235	1	outdoor_temp	2.8	2026-06-20 05:18:08.237
1236	1	outdoor_temp	1.2	2026-06-20 05:33:08.237
1237	1	outdoor_temp	1.8	2026-06-20 05:48:08.237
1238	1	outdoor_temp	2.3	2026-06-20 06:03:08.237
1239	1	outdoor_temp	2.5	2026-06-20 06:18:08.237
1240	1	outdoor_temp	2.5	2026-06-20 06:33:08.237
1241	1	outdoor_temp	2.4	2026-06-20 06:48:08.237
1242	1	outdoor_temp	2.5	2026-06-20 07:03:08.237
1243	1	outdoor_temp	1.8	2026-06-20 07:18:08.237
1244	1	outdoor_temp	2.1	2026-06-20 07:33:08.237
1245	1	outdoor_temp	1.8	2026-06-20 07:48:08.237
1246	1	outdoor_temp	0.8	2026-06-20 08:03:08.237
1247	1	outdoor_temp	2.1	2026-06-20 08:18:08.237
1248	1	outdoor_temp	1.4	2026-06-20 08:33:08.237
1249	1	outdoor_temp	0.3	2026-06-20 08:48:08.237
1250	1	outdoor_temp	0.3	2026-06-20 09:03:08.237
1251	1	outdoor_temp	0.2	2026-06-20 09:18:08.237
1252	1	outdoor_temp	-0.2	2026-06-20 09:33:08.237
1253	1	outdoor_temp	1.1	2026-06-20 09:48:08.237
1254	1	outdoor_temp	-0.3	2026-06-20 10:03:08.237
1255	1	outdoor_temp	-1.3	2026-06-20 10:18:08.237
1256	1	outdoor_temp	-0.6	2026-06-20 10:33:08.237
1257	1	outdoor_temp	-0.2	2026-06-20 10:48:08.237
1258	1	outdoor_temp	-1.8	2026-06-20 11:03:08.237
1259	1	outdoor_temp	-1.4	2026-06-20 11:18:08.237
1260	1	outdoor_temp	-1.0	2026-06-20 11:33:08.237
1261	1	outdoor_temp	-1.7	2026-06-20 11:48:08.237
1262	1	outdoor_temp	-2.4	2026-06-20 12:03:08.237
1263	1	outdoor_temp	-2.5	2026-06-20 12:18:08.237
1264	1	outdoor_temp	-3.0	2026-06-20 12:33:08.237
1265	1	outdoor_temp	-4.0	2026-06-20 12:48:08.237
1266	1	outdoor_temp	-4.6	2026-06-20 13:03:08.237
1267	1	outdoor_temp	-3.9	2026-06-20 13:18:08.237
1268	1	outdoor_temp	-4.1	2026-06-20 13:33:08.237
1269	1	outdoor_temp	-5.1	2026-06-20 13:48:08.237
1270	1	outdoor_temp	-4.8	2026-06-20 14:03:08.237
1271	1	outdoor_temp	-5.9	2026-06-20 14:18:08.237
1272	1	outdoor_temp	-6.0	2026-06-20 14:33:08.237
1273	1	outdoor_temp	-5.4	2026-06-20 14:48:08.237
1274	1	outdoor_temp	-7.2	2026-06-20 15:03:08.237
1275	1	outdoor_temp	-6.1	2026-06-20 15:18:08.237
1276	1	outdoor_temp	-6.4	2026-06-20 15:33:08.237
1277	1	outdoor_temp	-6.5	2026-06-20 15:48:08.237
1278	1	outdoor_temp	-8.2	2026-06-20 16:03:08.237
1279	1	outdoor_temp	-7.8	2026-06-20 16:18:08.237
1280	1	outdoor_temp	-8.2	2026-06-20 16:33:08.237
1281	1	outdoor_temp	-8.2	2026-06-20 16:48:08.237
1282	1	outdoor_temp	-7.5	2026-06-20 17:03:08.237
1283	1	outdoor_temp	-8.3	2026-06-20 17:18:08.237
1284	1	outdoor_temp	-8.4	2026-06-20 17:33:08.237
1285	1	outdoor_temp	-8.2	2026-06-20 17:48:08.237
1286	1	outdoor_temp	-8.9	2026-06-20 18:03:08.237
1287	1	outdoor_temp	-8.4	2026-06-20 18:18:08.237
1288	1	outdoor_temp	-8.4	2026-06-20 18:33:08.237
1289	1	outdoor_temp	-8.4	2026-06-20 18:48:08.237
1290	1	outdoor_temp	-7.4	2026-06-20 19:03:08.237
1291	1	outdoor_temp	-8.7	2026-06-20 19:18:08.237
1292	1	outdoor_temp	-8.0	2026-06-20 19:33:08.237
1293	1	outdoor_temp	-7.9	2026-06-20 19:48:08.237
1294	1	outdoor_temp	-8.2	2026-06-20 20:03:08.237
1295	1	outdoor_temp	-8.0	2026-06-20 20:18:08.237
1296	1	outdoor_temp	-8.1	2026-06-20 20:33:08.237
1297	1	outdoor_temp	-6.6	2026-06-20 20:48:08.237
1298	1	outdoor_temp	-6.9	2026-06-20 21:03:08.237
1299	1	outdoor_temp	-6.6	2026-06-20 21:18:08.237
1300	1	outdoor_temp	-6.9	2026-06-20 21:33:08.237
1301	1	outdoor_temp	-7.4	2026-06-20 21:48:08.237
1302	1	outdoor_temp	-4.8	2026-06-20 22:03:08.237
1303	1	outdoor_temp	-5.3	2026-06-20 22:18:08.237
1304	1	outdoor_temp	-5.5	2026-06-20 22:33:08.237
1305	1	outdoor_temp	-5.9	2026-06-20 22:48:08.237
1306	1	outdoor_temp	-3.4	2026-06-20 23:03:08.237
1307	1	outdoor_temp	-5.2	2026-06-20 23:18:08.237
1308	1	outdoor_temp	-3.6	2026-06-20 23:33:08.237
1309	1	outdoor_temp	-4.2	2026-06-20 23:48:08.237
1310	1	outdoor_temp	-2.5	2026-06-21 00:03:08.237
1311	1	outdoor_temp	-3.5	2026-06-21 00:18:08.237
1312	1	outdoor_temp	-3.6	2026-06-21 00:33:08.237
1313	1	outdoor_temp	-3.7	2026-06-21 00:48:08.237
1314	1	outdoor_temp	-2.1	2026-06-21 01:03:08.237
1315	1	outdoor_temp	-1.4	2026-06-21 01:18:08.237
1316	1	outdoor_temp	-1.3	2026-06-21 01:33:08.237
1317	1	outdoor_temp	-1.7	2026-06-21 01:48:08.237
1318	1	outdoor_temp	-1.3	2026-06-21 02:03:08.237
1319	1	outdoor_temp	0.0	2026-06-21 02:18:08.237
1320	1	outdoor_temp	0.1	2026-06-21 02:33:08.237
1321	1	outdoor_temp	-0.7	2026-06-21 02:48:08.237
1322	1	outdoor_temp	1.4	2026-06-21 03:03:08.237
1323	1	outdoor_temp	0.9	2026-06-21 03:18:08.237
1324	1	outdoor_temp	0.6	2026-06-21 03:33:08.237
1325	1	outdoor_temp	0.6	2026-06-21 03:48:08.237
1326	1	outdoor_temp	0.8	2026-06-21 04:03:08.237
1327	1	outdoor_temp	1.4	2026-06-21 04:18:08.237
1328	1	outdoor_temp	1.4	2026-06-21 04:33:08.237
1329	1	outdoor_temp	1.5	2026-06-21 04:48:08.237
1330	1	outdoor_temp	1.1	2026-06-21 05:03:08.237
1331	1	outdoor_temp	1.8	2026-06-21 05:18:08.237
1332	1	outdoor_temp	2.6	2026-06-21 05:33:08.237
1333	1	outdoor_temp	2.8	2026-06-21 05:48:08.237
1334	1	outdoor_temp	2.5	2026-06-21 06:03:08.237
1335	1	outdoor_temp	2.0	2026-06-21 06:18:08.237
1336	1	outdoor_temp	2.9	2026-06-21 06:33:08.237
1337	1	outdoor_temp	2.7	2026-06-21 06:48:08.237
1338	1	outdoor_temp	0.9	2026-06-21 07:03:08.237
1339	1	outdoor_temp	1.3	2026-06-21 07:18:08.237
1340	1	outdoor_temp	2.8	2026-06-21 07:33:08.237
1341	1	outdoor_temp	2.5	2026-06-21 07:48:08.237
1342	1	outdoor_temp	1.1	2026-06-21 08:03:08.237
1343	1	outdoor_temp	0.8	2026-06-21 08:18:08.237
1344	1	outdoor_temp	1.1	2026-06-21 08:33:08.237
1345	1	outdoor_temp	1.9	2026-06-21 08:48:08.237
1346	1	outdoor_temp	1.5	2026-06-21 09:03:08.237
1347	1	boiler_temp	44.5	2026-06-14 09:03:16.223
1348	1	boiler_temp	45.2	2026-06-14 09:18:16.223
1349	1	boiler_temp	44.2	2026-06-14 09:33:16.223
1350	1	boiler_temp	43.7	2026-06-14 09:48:16.223
1351	1	boiler_temp	45.4	2026-06-14 10:03:16.223
1352	1	boiler_temp	47.2	2026-06-14 10:18:16.223
1353	1	boiler_temp	47.3	2026-06-14 10:33:16.223
1354	1	boiler_temp	44.9	2026-06-14 10:48:16.223
1355	1	boiler_temp	51.4	2026-06-14 11:03:16.223
1356	1	boiler_temp	51.2	2026-06-14 11:18:16.223
1357	1	boiler_temp	48.7	2026-06-14 11:33:16.223
1358	1	boiler_temp	48.7	2026-06-14 11:48:16.223
1359	1	boiler_temp	56.5	2026-06-14 12:03:16.223
1360	1	boiler_temp	54.1	2026-06-14 12:18:16.223
1361	1	boiler_temp	53.9	2026-06-14 12:33:16.223
1362	1	boiler_temp	55.0	2026-06-14 12:48:16.223
1363	1	boiler_temp	59.9	2026-06-14 13:03:16.223
1364	1	boiler_temp	59.2	2026-06-14 13:18:16.223
1365	1	boiler_temp	60.5	2026-06-14 13:33:16.223
1366	1	boiler_temp	59.8	2026-06-14 13:48:16.223
1367	1	boiler_temp	63.9	2026-06-14 14:03:16.223
1368	1	boiler_temp	64.0	2026-06-14 14:18:16.223
1369	1	boiler_temp	64.5	2026-06-14 14:33:16.223
1370	1	boiler_temp	63.5	2026-06-14 14:48:16.223
1371	1	boiler_temp	64.6	2026-06-14 15:03:16.223
1372	1	boiler_temp	66.3	2026-06-14 15:18:16.223
1373	1	boiler_temp	64.5	2026-06-14 15:33:16.223
1374	1	boiler_temp	63.7	2026-06-14 15:48:16.223
1375	1	boiler_temp	64.6	2026-06-14 16:03:16.223
1376	1	boiler_temp	62.4	2026-06-14 16:18:16.223
1377	1	boiler_temp	64.2	2026-06-14 16:33:16.223
1378	1	boiler_temp	62.6	2026-06-14 16:48:16.223
1379	1	boiler_temp	58.6	2026-06-14 17:03:16.223
1380	1	boiler_temp	61.2	2026-06-14 17:18:16.223
1381	1	boiler_temp	59.7	2026-06-14 17:33:16.223
1382	1	boiler_temp	59.5	2026-06-14 17:48:16.223
1383	1	boiler_temp	56.2	2026-06-14 18:03:16.223
1384	1	boiler_temp	54.3	2026-06-14 18:18:16.223
1385	1	boiler_temp	54.6	2026-06-14 18:33:16.223
1386	1	boiler_temp	54.0	2026-06-14 18:48:16.223
1387	1	boiler_temp	49.5	2026-06-14 19:03:16.223
1388	1	boiler_temp	49.9	2026-06-14 19:18:16.223
1389	1	boiler_temp	50.5	2026-06-14 19:33:16.223
1390	1	boiler_temp	50.7	2026-06-14 19:48:16.223
1391	1	boiler_temp	45.0	2026-06-14 20:03:16.223
1392	1	boiler_temp	46.0	2026-06-14 20:18:16.223
1393	1	boiler_temp	45.2	2026-06-14 20:33:16.223
1394	1	boiler_temp	45.1	2026-06-14 20:48:16.223
1395	1	boiler_temp	44.2	2026-06-14 21:03:16.223
1396	1	boiler_temp	44.1	2026-06-14 21:18:16.223
1397	1	boiler_temp	44.5	2026-06-14 21:33:16.223
1398	1	boiler_temp	46.1	2026-06-14 21:48:16.223
1399	1	boiler_temp	46.6	2026-06-14 22:03:16.223
1400	1	boiler_temp	45.5	2026-06-14 22:18:16.223
1401	1	boiler_temp	45.0	2026-06-14 22:33:16.223
1402	1	boiler_temp	46.3	2026-06-14 22:48:16.223
1403	1	boiler_temp	50.9	2026-06-14 23:03:16.223
1404	1	boiler_temp	49.6	2026-06-14 23:18:16.223
1405	1	boiler_temp	51.1	2026-06-14 23:33:16.223
1406	1	boiler_temp	49.9	2026-06-14 23:48:16.223
1407	1	boiler_temp	54.0	2026-06-15 00:03:16.223
1408	1	boiler_temp	54.6	2026-06-15 00:18:16.223
1409	1	boiler_temp	55.9	2026-06-15 00:33:16.223
1410	1	boiler_temp	55.9	2026-06-15 00:48:16.223
1411	1	boiler_temp	59.5	2026-06-15 01:03:16.223
1412	1	boiler_temp	58.6	2026-06-15 01:18:16.223
1413	1	boiler_temp	60.2	2026-06-15 01:33:16.223
1414	1	boiler_temp	58.8	2026-06-15 01:48:16.223
1415	1	boiler_temp	63.1	2026-06-15 02:03:16.223
1416	1	boiler_temp	62.4	2026-06-15 02:18:16.223
1417	1	boiler_temp	65.1	2026-06-15 02:33:16.223
1418	1	boiler_temp	62.9	2026-06-15 02:48:16.223
1419	1	boiler_temp	65.2	2026-06-15 03:03:16.223
1420	1	boiler_temp	65.1	2026-06-15 03:18:16.223
1421	1	boiler_temp	65.4	2026-06-15 03:33:16.223
1422	1	boiler_temp	65.7	2026-06-15 03:48:16.223
1423	1	boiler_temp	64.6	2026-06-15 04:03:16.223
1424	1	boiler_temp	64.2	2026-06-15 04:18:16.223
1425	1	boiler_temp	64.7	2026-06-15 04:33:16.223
1426	1	boiler_temp	63.6	2026-06-15 04:48:16.223
1427	1	boiler_temp	61.0	2026-06-15 05:03:16.223
1428	1	boiler_temp	60.4	2026-06-15 05:18:16.223
1429	1	boiler_temp	58.9	2026-06-15 05:33:16.223
1430	1	boiler_temp	60.0	2026-06-15 05:48:16.223
1431	1	boiler_temp	54.5	2026-06-15 06:03:16.223
1432	1	boiler_temp	55.5	2026-06-15 06:18:16.223
1433	1	boiler_temp	54.1	2026-06-15 06:33:16.223
1434	1	boiler_temp	54.4	2026-06-15 06:48:16.223
1435	1	boiler_temp	50.2	2026-06-15 07:03:16.223
1436	1	boiler_temp	48.8	2026-06-15 07:18:16.223
1437	1	boiler_temp	50.7	2026-06-15 07:33:16.223
1438	1	boiler_temp	49.4	2026-06-15 07:48:16.223
1439	1	boiler_temp	45.5	2026-06-15 08:03:16.223
1440	1	boiler_temp	46.3	2026-06-15 08:18:16.223
1441	1	boiler_temp	47.0	2026-06-15 08:33:16.223
1442	1	boiler_temp	46.4	2026-06-15 08:48:16.223
1443	1	boiler_temp	43.9	2026-06-15 09:03:16.223
1444	1	boiler_temp	45.8	2026-06-15 09:18:16.223
1445	1	boiler_temp	45.1	2026-06-15 09:33:16.223
1446	1	boiler_temp	44.3	2026-06-15 09:48:16.223
1447	1	boiler_temp	45.4	2026-06-15 10:03:16.223
1448	1	boiler_temp	46.8	2026-06-15 10:18:16.223
1449	1	boiler_temp	47.7	2026-06-15 10:33:16.223
1450	1	boiler_temp	45.7	2026-06-15 10:48:16.223
1451	1	boiler_temp	50.4	2026-06-15 11:03:16.223
1452	1	boiler_temp	49.3	2026-06-15 11:18:16.223
1453	1	boiler_temp	50.6	2026-06-15 11:33:16.223
1454	1	boiler_temp	48.7	2026-06-15 11:48:16.223
1455	1	boiler_temp	54.7	2026-06-15 12:03:16.223
1456	1	boiler_temp	54.1	2026-06-15 12:18:16.223
1457	1	boiler_temp	53.9	2026-06-15 12:33:16.223
1458	1	boiler_temp	53.6	2026-06-15 12:48:16.223
1459	1	boiler_temp	61.1	2026-06-15 13:03:16.223
1460	1	boiler_temp	58.5	2026-06-15 13:18:16.223
1461	1	boiler_temp	60.3	2026-06-15 13:33:16.223
1462	1	boiler_temp	61.3	2026-06-15 13:48:16.223
1463	1	boiler_temp	63.0	2026-06-15 14:03:16.223
1464	1	boiler_temp	62.4	2026-06-15 14:18:16.223
1465	1	boiler_temp	64.0	2026-06-15 14:33:16.223
1466	1	boiler_temp	64.8	2026-06-15 14:48:16.223
1467	1	boiler_temp	64.3	2026-06-15 15:03:16.223
1468	1	boiler_temp	65.3	2026-06-15 15:18:16.223
1469	1	boiler_temp	64.7	2026-06-15 15:33:16.223
1470	1	boiler_temp	64.2	2026-06-15 15:48:16.223
1471	1	boiler_temp	64.3	2026-06-15 16:03:16.223
1472	1	boiler_temp	64.9	2026-06-15 16:18:16.223
1473	1	boiler_temp	63.1	2026-06-15 16:33:16.223
1474	1	boiler_temp	64.2	2026-06-15 16:48:16.223
1475	1	boiler_temp	61.5	2026-06-15 17:03:16.223
1476	1	boiler_temp	60.4	2026-06-15 17:18:16.223
1477	1	boiler_temp	59.2	2026-06-15 17:33:16.223
1478	1	boiler_temp	59.3	2026-06-15 17:48:16.223
1479	1	boiler_temp	56.4	2026-06-15 18:03:16.223
1480	1	boiler_temp	55.8	2026-06-15 18:18:16.223
1481	1	boiler_temp	55.9	2026-06-15 18:33:16.223
1482	1	boiler_temp	54.1	2026-06-15 18:48:16.223
1483	1	boiler_temp	49.0	2026-06-15 19:03:16.223
1484	1	boiler_temp	50.8	2026-06-15 19:18:16.223
1485	1	boiler_temp	50.9	2026-06-15 19:33:16.223
1486	1	boiler_temp	50.6	2026-06-15 19:48:16.223
1487	1	boiler_temp	45.6	2026-06-15 20:03:16.223
1488	1	boiler_temp	45.6	2026-06-15 20:18:16.223
1489	1	boiler_temp	45.8	2026-06-15 20:33:16.223
1490	1	boiler_temp	44.9	2026-06-15 20:48:16.223
1491	1	boiler_temp	44.5	2026-06-15 21:03:16.223
1492	1	boiler_temp	46.3	2026-06-15 21:18:16.223
1493	1	boiler_temp	44.0	2026-06-15 21:33:16.223
1494	1	boiler_temp	44.3	2026-06-15 21:48:16.223
1495	1	boiler_temp	46.8	2026-06-15 22:03:16.223
1496	1	boiler_temp	45.1	2026-06-15 22:18:16.223
1497	1	boiler_temp	47.3	2026-06-15 22:33:16.223
1498	1	boiler_temp	46.8	2026-06-15 22:48:16.223
1499	1	boiler_temp	51.0	2026-06-15 23:03:16.223
1500	1	boiler_temp	51.3	2026-06-15 23:18:16.223
1501	1	boiler_temp	48.5	2026-06-15 23:33:16.223
1502	1	boiler_temp	49.1	2026-06-15 23:48:16.223
1503	1	boiler_temp	55.7	2026-06-16 00:03:16.223
1504	1	boiler_temp	56.0	2026-06-16 00:18:16.223
1505	1	boiler_temp	54.5	2026-06-16 00:33:16.223
1506	1	boiler_temp	55.9	2026-06-16 00:48:16.223
1507	1	boiler_temp	59.7	2026-06-16 01:03:16.223
1508	1	boiler_temp	61.3	2026-06-16 01:18:16.223
1509	1	boiler_temp	58.7	2026-06-16 01:33:16.223
1510	1	boiler_temp	60.6	2026-06-16 01:48:16.223
1511	1	boiler_temp	62.9	2026-06-16 02:03:16.223
1512	1	boiler_temp	64.0	2026-06-16 02:18:16.223
1513	1	boiler_temp	64.3	2026-06-16 02:33:16.223
1514	1	boiler_temp	62.4	2026-06-16 02:48:16.223
1515	1	boiler_temp	63.6	2026-06-16 03:03:16.223
1516	1	boiler_temp	64.4	2026-06-16 03:18:16.223
1517	1	boiler_temp	66.4	2026-06-16 03:33:16.223
1518	1	boiler_temp	65.9	2026-06-16 03:48:16.223
1519	1	boiler_temp	63.4	2026-06-16 04:03:16.223
1520	1	boiler_temp	62.5	2026-06-16 04:18:16.223
1521	1	boiler_temp	64.9	2026-06-16 04:33:16.223
1522	1	boiler_temp	62.9	2026-06-16 04:48:16.223
1523	1	boiler_temp	58.8	2026-06-16 05:03:16.223
1524	1	boiler_temp	61.3	2026-06-16 05:18:16.223
1525	1	boiler_temp	60.2	2026-06-16 05:33:16.223
1526	1	boiler_temp	58.8	2026-06-16 05:48:16.223
1527	1	boiler_temp	56.1	2026-06-16 06:03:16.223
1528	1	boiler_temp	55.5	2026-06-16 06:18:16.223
1529	1	boiler_temp	56.1	2026-06-16 06:33:16.223
1530	1	boiler_temp	53.8	2026-06-16 06:48:16.223
1531	1	boiler_temp	49.7	2026-06-16 07:03:16.223
1532	1	boiler_temp	49.4	2026-06-16 07:18:16.223
1533	1	boiler_temp	51.1	2026-06-16 07:33:16.223
1534	1	boiler_temp	50.5	2026-06-16 07:48:16.223
1535	1	boiler_temp	45.9	2026-06-16 08:03:16.223
1536	1	boiler_temp	45.4	2026-06-16 08:18:16.223
1537	1	boiler_temp	47.8	2026-06-16 08:33:16.223
1538	1	boiler_temp	45.4	2026-06-16 08:48:16.223
1539	1	boiler_temp	46.2	2026-06-16 09:03:16.223
1540	1	boiler_temp	43.7	2026-06-16 09:18:16.223
1541	1	boiler_temp	44.3	2026-06-16 09:33:16.223
1542	1	boiler_temp	46.2	2026-06-16 09:48:16.223
1543	1	boiler_temp	47.1	2026-06-16 10:03:16.223
1544	1	boiler_temp	47.4	2026-06-16 10:18:16.223
1545	1	boiler_temp	47.0	2026-06-16 10:33:16.223
1546	1	boiler_temp	47.7	2026-06-16 10:48:16.223
1547	1	boiler_temp	50.5	2026-06-16 11:03:16.223
1548	1	boiler_temp	51.2	2026-06-16 11:18:16.223
1549	1	boiler_temp	50.8	2026-06-16 11:33:16.223
1550	1	boiler_temp	48.9	2026-06-16 11:48:16.223
1551	1	boiler_temp	55.3	2026-06-16 12:03:16.223
1552	1	boiler_temp	55.4	2026-06-16 12:18:16.223
1553	1	boiler_temp	54.7	2026-06-16 12:33:16.223
1554	1	boiler_temp	53.8	2026-06-16 12:48:16.223
1555	1	boiler_temp	60.4	2026-06-16 13:03:16.223
1556	1	boiler_temp	59.6	2026-06-16 13:18:16.223
1557	1	boiler_temp	58.9	2026-06-16 13:33:16.223
1558	1	boiler_temp	58.5	2026-06-16 13:48:16.223
1559	1	boiler_temp	63.0	2026-06-16 14:03:16.223
1560	1	boiler_temp	63.9	2026-06-16 14:18:16.223
1561	1	boiler_temp	62.5	2026-06-16 14:33:16.223
1562	1	boiler_temp	63.2	2026-06-16 14:48:16.223
1563	1	boiler_temp	66.1	2026-06-16 15:03:16.223
1564	1	boiler_temp	65.6	2026-06-16 15:18:16.223
1565	1	boiler_temp	66.2	2026-06-16 15:33:16.223
1566	1	boiler_temp	66.2	2026-06-16 15:48:16.223
1567	1	boiler_temp	62.2	2026-06-16 16:03:16.223
1568	1	boiler_temp	64.9	2026-06-16 16:18:16.223
1569	1	boiler_temp	63.2	2026-06-16 16:33:16.223
1570	1	boiler_temp	62.7	2026-06-16 16:48:16.223
1571	1	boiler_temp	58.7	2026-06-16 17:03:16.223
1572	1	boiler_temp	60.5	2026-06-16 17:18:16.223
1573	1	boiler_temp	59.2	2026-06-16 17:33:16.223
1574	1	boiler_temp	60.3	2026-06-16 17:48:16.223
1575	1	boiler_temp	56.4	2026-06-16 18:03:16.223
1576	1	boiler_temp	55.2	2026-06-16 18:18:16.223
1577	1	boiler_temp	55.9	2026-06-16 18:33:16.223
1578	1	boiler_temp	55.0	2026-06-16 18:48:16.223
1579	1	boiler_temp	50.7	2026-06-16 19:03:16.223
1580	1	boiler_temp	50.9	2026-06-16 19:18:16.223
1581	1	boiler_temp	48.9	2026-06-16 19:33:16.223
1582	1	boiler_temp	48.8	2026-06-16 19:48:16.223
1583	1	boiler_temp	46.1	2026-06-16 20:03:16.223
1584	1	boiler_temp	47.8	2026-06-16 20:18:16.223
1585	1	boiler_temp	46.9	2026-06-16 20:33:16.223
1586	1	boiler_temp	47.6	2026-06-16 20:48:16.223
1587	1	boiler_temp	44.7	2026-06-16 21:03:16.223
1588	1	boiler_temp	46.4	2026-06-16 21:18:16.223
1589	1	boiler_temp	45.5	2026-06-16 21:33:16.223
1590	1	boiler_temp	44.7	2026-06-16 21:48:16.223
1591	1	boiler_temp	47.5	2026-06-16 22:03:16.223
1592	1	boiler_temp	46.6	2026-06-16 22:18:16.223
1593	1	boiler_temp	47.4	2026-06-16 22:33:16.223
1594	1	boiler_temp	46.2	2026-06-16 22:48:16.223
1595	1	boiler_temp	49.5	2026-06-16 23:03:16.223
1596	1	boiler_temp	48.5	2026-06-16 23:18:16.223
1597	1	boiler_temp	49.8	2026-06-16 23:33:16.223
1598	1	boiler_temp	49.2	2026-06-16 23:48:16.223
1599	1	boiler_temp	54.6	2026-06-17 00:03:16.223
1600	1	boiler_temp	53.8	2026-06-17 00:18:16.223
1601	1	boiler_temp	56.0	2026-06-17 00:33:16.223
1602	1	boiler_temp	55.2	2026-06-17 00:48:16.223
1603	1	boiler_temp	59.3	2026-06-17 01:03:16.223
1604	1	boiler_temp	60.7	2026-06-17 01:18:16.223
1605	1	boiler_temp	61.1	2026-06-17 01:33:16.223
1606	1	boiler_temp	60.9	2026-06-17 01:48:16.223
1607	1	boiler_temp	64.1	2026-06-17 02:03:16.223
1608	1	boiler_temp	63.3	2026-06-17 02:18:16.223
1609	1	boiler_temp	63.5	2026-06-17 02:33:16.223
1610	1	boiler_temp	62.7	2026-06-17 02:48:16.223
1611	1	boiler_temp	65.5	2026-06-17 03:03:16.223
1612	1	boiler_temp	66.1	2026-06-17 03:18:16.223
1613	1	boiler_temp	64.9	2026-06-17 03:33:16.223
1614	1	boiler_temp	66.5	2026-06-17 03:48:16.223
1615	1	boiler_temp	65.1	2026-06-17 04:03:16.223
1616	1	boiler_temp	64.7	2026-06-17 04:18:16.223
1617	1	boiler_temp	63.7	2026-06-17 04:33:16.223
1618	1	boiler_temp	64.6	2026-06-17 04:48:16.223
1619	1	boiler_temp	61.1	2026-06-17 05:03:16.223
1620	1	boiler_temp	59.0	2026-06-17 05:18:16.223
1621	1	boiler_temp	59.7	2026-06-17 05:33:16.223
1622	1	boiler_temp	60.2	2026-06-17 05:48:16.223
1623	1	boiler_temp	55.6	2026-06-17 06:03:16.223
1624	1	boiler_temp	55.9	2026-06-17 06:18:16.223
1625	1	boiler_temp	56.1	2026-06-17 06:33:16.223
1626	1	boiler_temp	56.3	2026-06-17 06:48:16.223
1627	1	boiler_temp	48.5	2026-06-17 07:03:16.223
1628	1	boiler_temp	49.2	2026-06-17 07:18:16.223
1629	1	boiler_temp	50.3	2026-06-17 07:33:16.223
1630	1	boiler_temp	51.2	2026-06-17 07:48:16.223
1631	1	boiler_temp	46.6	2026-06-17 08:03:16.223
1632	1	boiler_temp	46.2	2026-06-17 08:18:16.223
1633	1	boiler_temp	45.3	2026-06-17 08:33:16.223
1634	1	boiler_temp	45.0	2026-06-17 08:48:16.223
1635	1	boiler_temp	43.9	2026-06-17 09:03:16.223
1636	1	boiler_temp	43.9	2026-06-17 09:18:16.223
1637	1	boiler_temp	44.6	2026-06-17 09:33:16.223
1638	1	boiler_temp	46.1	2026-06-17 09:48:16.223
1639	1	boiler_temp	45.6	2026-06-17 10:03:16.223
1640	1	boiler_temp	46.2	2026-06-17 10:18:16.223
1641	1	boiler_temp	45.7	2026-06-17 10:33:16.223
1642	1	boiler_temp	47.0	2026-06-17 10:48:16.223
1643	1	boiler_temp	48.7	2026-06-17 11:03:16.223
1644	1	boiler_temp	49.9	2026-06-17 11:18:16.223
1645	1	boiler_temp	50.3	2026-06-17 11:33:16.223
1646	1	boiler_temp	50.1	2026-06-17 11:48:16.223
1647	1	boiler_temp	54.6	2026-06-17 12:03:16.223
1648	1	boiler_temp	54.6	2026-06-17 12:18:16.223
1649	1	boiler_temp	55.3	2026-06-17 12:33:16.223
1650	1	boiler_temp	55.8	2026-06-17 12:48:16.223
1651	1	boiler_temp	59.1	2026-06-17 13:03:16.223
1652	1	boiler_temp	59.3	2026-06-17 13:18:16.223
1653	1	boiler_temp	61.0	2026-06-17 13:33:16.223
1654	1	boiler_temp	58.9	2026-06-17 13:48:16.223
1655	1	boiler_temp	62.5	2026-06-17 14:03:16.223
1656	1	boiler_temp	63.9	2026-06-17 14:18:16.223
1657	1	boiler_temp	63.7	2026-06-17 14:33:16.223
1658	1	boiler_temp	62.7	2026-06-17 14:48:16.223
1659	1	boiler_temp	65.5	2026-06-17 15:03:16.223
1660	1	boiler_temp	64.9	2026-06-17 15:18:16.223
1661	1	boiler_temp	63.9	2026-06-17 15:33:16.223
1662	1	boiler_temp	65.3	2026-06-17 15:48:16.223
1663	1	boiler_temp	62.5	2026-06-17 16:03:16.223
1664	1	boiler_temp	64.7	2026-06-17 16:18:16.223
1665	1	boiler_temp	63.1	2026-06-17 16:33:16.223
1666	1	boiler_temp	63.2	2026-06-17 16:48:16.223
1667	1	boiler_temp	59.9	2026-06-17 17:03:16.223
1668	1	boiler_temp	59.9	2026-06-17 17:18:16.223
1669	1	boiler_temp	60.3	2026-06-17 17:33:16.223
1670	1	boiler_temp	59.9	2026-06-17 17:48:16.223
1671	1	boiler_temp	56.4	2026-06-17 18:03:16.223
1672	1	boiler_temp	54.0	2026-06-17 18:18:16.223
1673	1	boiler_temp	56.4	2026-06-17 18:33:16.223
1674	1	boiler_temp	54.7	2026-06-17 18:48:16.223
1675	1	boiler_temp	51.1	2026-06-17 19:03:16.223
1676	1	boiler_temp	50.2	2026-06-17 19:18:16.223
1677	1	boiler_temp	48.9	2026-06-17 19:33:16.223
1678	1	boiler_temp	48.7	2026-06-17 19:48:16.223
1679	1	boiler_temp	46.3	2026-06-17 20:03:16.223
1680	1	boiler_temp	47.6	2026-06-17 20:18:16.223
1681	1	boiler_temp	47.4	2026-06-17 20:33:16.223
1682	1	boiler_temp	46.5	2026-06-17 20:48:16.223
1683	1	boiler_temp	44.1	2026-06-17 21:03:16.223
1684	1	boiler_temp	45.1	2026-06-17 21:18:16.223
1685	1	boiler_temp	46.0	2026-06-17 21:33:16.223
1686	1	boiler_temp	45.7	2026-06-17 21:48:16.223
1687	1	boiler_temp	47.6	2026-06-17 22:03:16.223
1688	1	boiler_temp	46.6	2026-06-17 22:18:16.223
1689	1	boiler_temp	46.8	2026-06-17 22:33:16.223
1690	1	boiler_temp	44.9	2026-06-17 22:48:16.223
1691	1	boiler_temp	49.4	2026-06-17 23:03:16.223
1692	1	boiler_temp	49.4	2026-06-17 23:18:16.223
1693	1	boiler_temp	49.0	2026-06-17 23:33:16.223
1694	1	boiler_temp	51.2	2026-06-17 23:48:16.223
1695	1	boiler_temp	54.6	2026-06-18 00:03:16.223
1696	1	boiler_temp	54.4	2026-06-18 00:18:16.223
1697	1	boiler_temp	55.9	2026-06-18 00:33:16.223
1698	1	boiler_temp	54.9	2026-06-18 00:48:16.223
1699	1	boiler_temp	59.8	2026-06-18 01:03:16.223
1700	1	boiler_temp	60.9	2026-06-18 01:18:16.223
1701	1	boiler_temp	58.8	2026-06-18 01:33:16.223
1702	1	boiler_temp	59.9	2026-06-18 01:48:16.223
1703	1	boiler_temp	63.5	2026-06-18 02:03:16.223
1704	1	boiler_temp	63.1	2026-06-18 02:18:16.223
1705	1	boiler_temp	64.2	2026-06-18 02:33:16.223
1706	1	boiler_temp	64.6	2026-06-18 02:48:16.223
1707	1	boiler_temp	64.0	2026-06-18 03:03:16.223
1708	1	boiler_temp	66.2	2026-06-18 03:18:16.223
1709	1	boiler_temp	64.0	2026-06-18 03:33:16.223
1710	1	boiler_temp	65.1	2026-06-18 03:48:16.223
1711	1	boiler_temp	64.4	2026-06-18 04:03:16.223
1712	1	boiler_temp	64.7	2026-06-18 04:18:16.223
1713	1	boiler_temp	63.2	2026-06-18 04:33:16.223
1714	1	boiler_temp	64.1	2026-06-18 04:48:16.223
1715	1	boiler_temp	59.2	2026-06-18 05:03:16.223
1716	1	boiler_temp	60.6	2026-06-18 05:18:16.223
1717	1	boiler_temp	59.4	2026-06-18 05:33:16.223
1718	1	boiler_temp	59.2	2026-06-18 05:48:16.223
1719	1	boiler_temp	56.0	2026-06-18 06:03:16.223
1720	1	boiler_temp	54.6	2026-06-18 06:18:16.223
1721	1	boiler_temp	56.4	2026-06-18 06:33:16.223
1722	1	boiler_temp	53.6	2026-06-18 06:48:16.223
1723	1	boiler_temp	49.0	2026-06-18 07:03:16.223
1724	1	boiler_temp	51.4	2026-06-18 07:18:16.223
1725	1	boiler_temp	51.2	2026-06-18 07:33:16.223
1726	1	boiler_temp	48.6	2026-06-18 07:48:16.223
1727	1	boiler_temp	46.2	2026-06-18 08:03:16.223
1728	1	boiler_temp	47.1	2026-06-18 08:18:16.223
1729	1	boiler_temp	45.6	2026-06-18 08:33:16.223
1730	1	boiler_temp	47.5	2026-06-18 08:48:16.223
1731	1	boiler_temp	43.9	2026-06-18 09:03:16.223
1732	1	boiler_temp	44.5	2026-06-18 09:18:16.223
1733	1	boiler_temp	43.7	2026-06-18 09:33:16.223
1734	1	boiler_temp	44.1	2026-06-18 09:48:16.223
1735	1	boiler_temp	46.9	2026-06-18 10:03:16.223
1736	1	boiler_temp	45.4	2026-06-18 10:18:16.223
1737	1	boiler_temp	47.5	2026-06-18 10:33:16.223
1738	1	boiler_temp	46.8	2026-06-18 10:48:16.223
1739	1	boiler_temp	48.7	2026-06-18 11:03:16.223
1740	1	boiler_temp	48.8	2026-06-18 11:18:16.223
1741	1	boiler_temp	50.9	2026-06-18 11:33:16.223
1742	1	boiler_temp	48.7	2026-06-18 11:48:16.223
1743	1	boiler_temp	53.6	2026-06-18 12:03:16.223
1744	1	boiler_temp	54.4	2026-06-18 12:18:16.223
1745	1	boiler_temp	55.0	2026-06-18 12:33:16.223
1746	1	boiler_temp	56.0	2026-06-18 12:48:16.223
1747	1	boiler_temp	59.3	2026-06-18 13:03:16.223
1748	1	boiler_temp	59.1	2026-06-18 13:18:16.223
1749	1	boiler_temp	59.0	2026-06-18 13:33:16.223
1750	1	boiler_temp	59.9	2026-06-18 13:48:16.223
1751	1	boiler_temp	64.3	2026-06-18 14:03:16.223
1752	1	boiler_temp	62.9	2026-06-18 14:18:16.223
1753	1	boiler_temp	62.4	2026-06-18 14:33:16.223
1754	1	boiler_temp	63.4	2026-06-18 14:48:16.223
1755	1	boiler_temp	66.5	2026-06-18 15:03:16.223
1756	1	boiler_temp	64.8	2026-06-18 15:18:16.223
1757	1	boiler_temp	65.4	2026-06-18 15:33:16.223
1758	1	boiler_temp	66.5	2026-06-18 15:48:16.223
1759	1	boiler_temp	62.3	2026-06-18 16:03:16.223
1760	1	boiler_temp	64.0	2026-06-18 16:18:16.223
1761	1	boiler_temp	63.7	2026-06-18 16:33:16.223
1762	1	boiler_temp	62.7	2026-06-18 16:48:16.223
1763	1	boiler_temp	60.5	2026-06-18 17:03:16.223
1764	1	boiler_temp	59.3	2026-06-18 17:18:16.223
1765	1	boiler_temp	59.6	2026-06-18 17:33:16.223
1766	1	boiler_temp	60.6	2026-06-18 17:48:16.223
1767	1	boiler_temp	54.4	2026-06-18 18:03:16.223
1768	1	boiler_temp	55.0	2026-06-18 18:18:16.223
1769	1	boiler_temp	54.5	2026-06-18 18:33:16.223
1770	1	boiler_temp	55.8	2026-06-18 18:48:16.223
1771	1	boiler_temp	49.8	2026-06-18 19:03:16.223
1772	1	boiler_temp	49.9	2026-06-18 19:18:16.223
1773	1	boiler_temp	49.8	2026-06-18 19:33:16.223
1774	1	boiler_temp	49.2	2026-06-18 19:48:16.223
1775	1	boiler_temp	45.9	2026-06-18 20:03:16.223
1776	1	boiler_temp	47.0	2026-06-18 20:18:16.223
1777	1	boiler_temp	46.4	2026-06-18 20:33:16.223
1778	1	boiler_temp	45.1	2026-06-18 20:48:16.223
1779	1	boiler_temp	46.4	2026-06-18 21:03:16.223
1780	1	boiler_temp	45.4	2026-06-18 21:18:16.223
1781	1	boiler_temp	45.0	2026-06-18 21:33:16.223
1782	1	boiler_temp	44.5	2026-06-18 21:48:16.223
1783	1	boiler_temp	45.3	2026-06-18 22:03:16.223
1784	1	boiler_temp	46.7	2026-06-18 22:18:16.223
1785	1	boiler_temp	45.9	2026-06-18 22:33:16.223
1786	1	boiler_temp	45.3	2026-06-18 22:48:16.223
1787	1	boiler_temp	48.6	2026-06-18 23:03:16.223
1788	1	boiler_temp	51.0	2026-06-18 23:18:16.223
1789	1	boiler_temp	48.8	2026-06-18 23:33:16.223
1790	1	boiler_temp	50.1	2026-06-18 23:48:16.223
1791	1	boiler_temp	55.4	2026-06-19 00:03:16.223
1792	1	boiler_temp	54.5	2026-06-19 00:18:16.223
1793	1	boiler_temp	56.2	2026-06-19 00:33:16.223
1794	1	boiler_temp	54.0	2026-06-19 00:48:16.223
1795	1	boiler_temp	60.1	2026-06-19 01:03:16.223
1796	1	boiler_temp	60.9	2026-06-19 01:18:16.223
1797	1	boiler_temp	60.6	2026-06-19 01:33:16.223
1798	1	boiler_temp	61.1	2026-06-19 01:48:16.223
1799	1	boiler_temp	64.5	2026-06-19 02:03:16.223
1800	1	boiler_temp	64.1	2026-06-19 02:18:16.223
1801	1	boiler_temp	63.6	2026-06-19 02:33:16.223
1802	1	boiler_temp	64.0	2026-06-19 02:48:16.223
1803	1	boiler_temp	64.9	2026-06-19 03:03:16.223
1804	1	boiler_temp	66.3	2026-06-19 03:18:16.223
1805	1	boiler_temp	66.2	2026-06-19 03:33:16.223
1806	1	boiler_temp	66.2	2026-06-19 03:48:16.223
1807	1	boiler_temp	64.6	2026-06-19 04:03:16.223
1808	1	boiler_temp	62.8	2026-06-19 04:18:16.223
1809	1	boiler_temp	63.6	2026-06-19 04:33:16.223
1810	1	boiler_temp	64.6	2026-06-19 04:48:16.223
1811	1	boiler_temp	58.6	2026-06-19 05:03:16.223
1812	1	boiler_temp	60.6	2026-06-19 05:18:16.223
1813	1	boiler_temp	59.8	2026-06-19 05:33:16.223
1814	1	boiler_temp	59.7	2026-06-19 05:48:16.223
1815	1	boiler_temp	55.2	2026-06-19 06:03:16.223
1816	1	boiler_temp	55.9	2026-06-19 06:18:16.223
1817	1	boiler_temp	54.6	2026-06-19 06:33:16.223
1818	1	boiler_temp	53.6	2026-06-19 06:48:16.223
1819	1	boiler_temp	49.6	2026-06-19 07:03:16.223
1820	1	boiler_temp	48.8	2026-06-19 07:18:16.223
1821	1	boiler_temp	50.4	2026-06-19 07:33:16.223
1822	1	boiler_temp	48.7	2026-06-19 07:48:16.223
1823	1	boiler_temp	45.4	2026-06-19 08:03:16.223
1824	1	boiler_temp	46.6	2026-06-19 08:18:16.223
1825	1	boiler_temp	45.4	2026-06-19 08:33:16.223
1826	1	boiler_temp	45.4	2026-06-19 08:48:16.223
1827	1	boiler_temp	44.2	2026-06-19 09:03:16.223
1828	1	boiler_temp	44.5	2026-06-19 09:18:16.223
1829	1	boiler_temp	44.2	2026-06-19 09:33:16.223
1830	1	boiler_temp	45.6	2026-06-19 09:48:16.223
1831	1	boiler_temp	45.8	2026-06-19 10:03:16.223
1832	1	boiler_temp	47.1	2026-06-19 10:18:16.223
1833	1	boiler_temp	45.6	2026-06-19 10:33:16.223
1834	1	boiler_temp	46.9	2026-06-19 10:48:16.223
1835	1	boiler_temp	51.3	2026-06-19 11:03:16.223
1836	1	boiler_temp	49.9	2026-06-19 11:18:16.223
1837	1	boiler_temp	49.0	2026-06-19 11:33:16.223
1838	1	boiler_temp	49.5	2026-06-19 11:48:16.223
1839	1	boiler_temp	56.0	2026-06-19 12:03:16.223
1840	1	boiler_temp	53.9	2026-06-19 12:18:16.223
1841	1	boiler_temp	54.9	2026-06-19 12:33:16.223
1842	1	boiler_temp	55.7	2026-06-19 12:48:16.223
1843	1	boiler_temp	59.1	2026-06-19 13:03:16.223
1844	1	boiler_temp	59.5	2026-06-19 13:18:16.223
1845	1	boiler_temp	59.2	2026-06-19 13:33:16.223
1846	1	boiler_temp	60.3	2026-06-19 13:48:16.223
1847	1	boiler_temp	62.3	2026-06-19 14:03:16.223
1848	1	boiler_temp	63.8	2026-06-19 14:18:16.223
1849	1	boiler_temp	62.6	2026-06-19 14:33:16.223
1850	1	boiler_temp	64.1	2026-06-19 14:48:16.223
1851	1	boiler_temp	64.9	2026-06-19 15:03:16.223
1852	1	boiler_temp	64.4	2026-06-19 15:18:16.223
1853	1	boiler_temp	64.2	2026-06-19 15:33:16.223
1854	1	boiler_temp	64.5	2026-06-19 15:48:16.223
1855	1	boiler_temp	62.8	2026-06-19 16:03:16.223
1856	1	boiler_temp	64.4	2026-06-19 16:18:16.223
1857	1	boiler_temp	63.5	2026-06-19 16:33:16.223
1858	1	boiler_temp	62.9	2026-06-19 16:48:16.223
1859	1	boiler_temp	59.5	2026-06-19 17:03:16.223
1860	1	boiler_temp	59.7	2026-06-19 17:18:16.223
1861	1	boiler_temp	59.4	2026-06-19 17:33:16.223
1862	1	boiler_temp	60.1	2026-06-19 17:48:16.223
1863	1	boiler_temp	56.1	2026-06-19 18:03:16.223
1864	1	boiler_temp	56.4	2026-06-19 18:18:16.223
1865	1	boiler_temp	56.4	2026-06-19 18:33:16.223
1866	1	boiler_temp	56.4	2026-06-19 18:48:16.223
1867	1	boiler_temp	49.8	2026-06-19 19:03:16.223
1868	1	boiler_temp	48.9	2026-06-19 19:18:16.223
1869	1	boiler_temp	49.0	2026-06-19 19:33:16.223
1870	1	boiler_temp	49.0	2026-06-19 19:48:16.223
1871	1	boiler_temp	47.1	2026-06-19 20:03:16.223
1872	1	boiler_temp	46.6	2026-06-19 20:18:16.223
1873	1	boiler_temp	47.4	2026-06-19 20:33:16.223
1874	1	boiler_temp	47.2	2026-06-19 20:48:16.223
1875	1	boiler_temp	44.3	2026-06-19 21:03:16.223
1876	1	boiler_temp	46.1	2026-06-19 21:18:16.223
1877	1	boiler_temp	44.1	2026-06-19 21:33:16.223
1878	1	boiler_temp	43.5	2026-06-19 21:48:16.223
1879	1	boiler_temp	46.2	2026-06-19 22:03:16.223
1880	1	boiler_temp	45.4	2026-06-19 22:18:16.223
1881	1	boiler_temp	46.5	2026-06-19 22:33:16.223
1882	1	boiler_temp	45.1	2026-06-19 22:48:16.223
1883	1	boiler_temp	50.7	2026-06-19 23:03:16.223
1884	1	boiler_temp	51.4	2026-06-19 23:18:16.223
1885	1	boiler_temp	50.0	2026-06-19 23:33:16.223
1886	1	boiler_temp	49.3	2026-06-19 23:48:16.223
1887	1	boiler_temp	54.8	2026-06-20 00:03:16.223
1888	1	boiler_temp	54.1	2026-06-20 00:18:16.223
1889	1	boiler_temp	54.0	2026-06-20 00:33:16.223
1890	1	boiler_temp	53.8	2026-06-20 00:48:16.223
1891	1	boiler_temp	59.1	2026-06-20 01:03:16.223
1892	1	boiler_temp	61.1	2026-06-20 01:18:16.223
1893	1	boiler_temp	59.4	2026-06-20 01:33:16.223
1894	1	boiler_temp	60.5	2026-06-20 01:48:16.223
1895	1	boiler_temp	62.2	2026-06-20 02:03:16.223
1896	1	boiler_temp	62.2	2026-06-20 02:18:16.223
1897	1	boiler_temp	62.2	2026-06-20 02:33:16.223
1898	1	boiler_temp	64.0	2026-06-20 02:48:16.223
1899	1	boiler_temp	64.5	2026-06-20 03:03:16.223
1900	1	boiler_temp	63.8	2026-06-20 03:18:16.223
1901	1	boiler_temp	65.6	2026-06-20 03:33:16.223
1902	1	boiler_temp	63.8	2026-06-20 03:48:16.223
1903	1	boiler_temp	62.3	2026-06-20 04:03:16.223
1904	1	boiler_temp	64.6	2026-06-20 04:18:16.223
1905	1	boiler_temp	63.7	2026-06-20 04:33:16.223
1906	1	boiler_temp	64.4	2026-06-20 04:48:16.223
1907	1	boiler_temp	59.5	2026-06-20 05:03:16.223
1908	1	boiler_temp	60.0	2026-06-20 05:18:16.223
1909	1	boiler_temp	58.6	2026-06-20 05:33:16.223
1910	1	boiler_temp	59.6	2026-06-20 05:48:16.223
1911	1	boiler_temp	55.7	2026-06-20 06:03:16.223
1912	1	boiler_temp	54.7	2026-06-20 06:18:16.223
1913	1	boiler_temp	53.7	2026-06-20 06:33:16.223
1914	1	boiler_temp	55.4	2026-06-20 06:48:16.223
1915	1	boiler_temp	49.7	2026-06-20 07:03:16.223
1916	1	boiler_temp	50.2	2026-06-20 07:18:16.223
1917	1	boiler_temp	50.9	2026-06-20 07:33:16.223
1918	1	boiler_temp	50.4	2026-06-20 07:48:16.223
1919	1	boiler_temp	45.6	2026-06-20 08:03:16.223
1920	1	boiler_temp	45.1	2026-06-20 08:18:16.223
1921	1	boiler_temp	47.6	2026-06-20 08:33:16.223
1922	1	boiler_temp	46.2	2026-06-20 08:48:16.223
1923	1	boiler_temp	44.2	2026-06-20 09:03:16.223
1924	1	boiler_temp	44.8	2026-06-20 09:18:16.223
1925	1	boiler_temp	44.1	2026-06-20 09:33:16.223
1926	1	boiler_temp	43.8	2026-06-20 09:48:16.223
1927	1	boiler_temp	47.3	2026-06-20 10:03:16.223
1928	1	boiler_temp	46.2	2026-06-20 10:18:16.223
1929	1	boiler_temp	47.0	2026-06-20 10:33:16.223
1930	1	boiler_temp	45.0	2026-06-20 10:48:16.223
1931	1	boiler_temp	49.8	2026-06-20 11:03:16.223
1932	1	boiler_temp	51.0	2026-06-20 11:18:16.223
1933	1	boiler_temp	49.6	2026-06-20 11:33:16.223
1934	1	boiler_temp	49.7	2026-06-20 11:48:16.223
1935	1	boiler_temp	55.6	2026-06-20 12:03:16.223
1936	1	boiler_temp	54.1	2026-06-20 12:18:16.223
1937	1	boiler_temp	54.2	2026-06-20 12:33:16.223
1938	1	boiler_temp	55.8	2026-06-20 12:48:16.223
1939	1	boiler_temp	61.3	2026-06-20 13:03:16.223
1940	1	boiler_temp	59.2	2026-06-20 13:18:16.223
1941	1	boiler_temp	61.5	2026-06-20 13:33:16.223
1942	1	boiler_temp	59.1	2026-06-20 13:48:16.223
1943	1	boiler_temp	63.4	2026-06-20 14:03:16.223
1944	1	boiler_temp	63.3	2026-06-20 14:18:16.223
1945	1	boiler_temp	64.5	2026-06-20 14:33:16.223
1946	1	boiler_temp	62.9	2026-06-20 14:48:16.223
1947	1	boiler_temp	63.8	2026-06-20 15:03:16.223
1948	1	boiler_temp	64.1	2026-06-20 15:18:16.223
1949	1	boiler_temp	64.0	2026-06-20 15:33:16.223
1950	1	boiler_temp	63.8	2026-06-20 15:48:16.223
1951	1	boiler_temp	63.4	2026-06-20 16:03:16.223
1952	1	boiler_temp	64.0	2026-06-20 16:18:16.223
1953	1	boiler_temp	63.1	2026-06-20 16:33:16.223
1954	1	boiler_temp	63.8	2026-06-20 16:48:16.223
1955	1	boiler_temp	58.9	2026-06-20 17:03:16.223
1956	1	boiler_temp	60.0	2026-06-20 17:18:16.223
1957	1	boiler_temp	60.0	2026-06-20 17:33:16.223
1958	1	boiler_temp	61.4	2026-06-20 17:48:16.223
1959	1	boiler_temp	54.1	2026-06-20 18:03:16.223
1960	1	boiler_temp	54.2	2026-06-20 18:18:16.223
1961	1	boiler_temp	53.9	2026-06-20 18:33:16.223
1962	1	boiler_temp	56.4	2026-06-20 18:48:16.223
1963	1	boiler_temp	50.6	2026-06-20 19:03:16.223
1964	1	boiler_temp	51.4	2026-06-20 19:18:16.223
1965	1	boiler_temp	48.6	2026-06-20 19:33:16.223
1966	1	boiler_temp	51.0	2026-06-20 19:48:16.223
1967	1	boiler_temp	46.0	2026-06-20 20:03:16.223
1968	1	boiler_temp	45.4	2026-06-20 20:18:16.223
1969	1	boiler_temp	45.8	2026-06-20 20:33:16.223
1970	1	boiler_temp	46.8	2026-06-20 20:48:16.223
1971	1	boiler_temp	45.7	2026-06-20 21:03:16.223
1972	1	boiler_temp	45.6	2026-06-20 21:18:16.223
1973	1	boiler_temp	45.5	2026-06-20 21:33:16.223
1974	1	boiler_temp	44.6	2026-06-20 21:48:16.223
1975	1	boiler_temp	45.9	2026-06-20 22:03:16.223
1976	1	boiler_temp	44.9	2026-06-20 22:18:16.223
1977	1	boiler_temp	47.6	2026-06-20 22:33:16.223
1978	1	boiler_temp	46.6	2026-06-20 22:48:16.223
1979	1	boiler_temp	48.9	2026-06-20 23:03:16.223
1980	1	boiler_temp	50.6	2026-06-20 23:18:16.223
1981	1	boiler_temp	51.5	2026-06-20 23:33:16.223
1982	1	boiler_temp	50.1	2026-06-20 23:48:16.223
1983	1	boiler_temp	55.5	2026-06-21 00:03:16.223
1984	1	boiler_temp	54.7	2026-06-21 00:18:16.223
1985	1	boiler_temp	54.5	2026-06-21 00:33:16.223
1986	1	boiler_temp	54.3	2026-06-21 00:48:16.223
1987	1	boiler_temp	61.4	2026-06-21 01:03:16.223
1988	1	boiler_temp	60.2	2026-06-21 01:18:16.223
1989	1	boiler_temp	59.4	2026-06-21 01:33:16.223
1990	1	boiler_temp	60.9	2026-06-21 01:48:16.223
1991	1	boiler_temp	64.4	2026-06-21 02:03:16.223
1992	1	boiler_temp	62.5	2026-06-21 02:18:16.223
1993	1	boiler_temp	63.6	2026-06-21 02:33:16.223
1994	1	boiler_temp	64.3	2026-06-21 02:48:16.223
1995	1	boiler_temp	64.6	2026-06-21 03:03:16.223
1996	1	boiler_temp	63.7	2026-06-21 03:18:16.223
1997	1	boiler_temp	64.4	2026-06-21 03:33:16.223
1998	1	boiler_temp	64.4	2026-06-21 03:48:16.223
1999	1	boiler_temp	64.3	2026-06-21 04:03:16.223
2000	1	boiler_temp	63.6	2026-06-21 04:18:16.223
2001	1	boiler_temp	65.1	2026-06-21 04:33:16.223
2002	1	boiler_temp	62.3	2026-06-21 04:48:16.223
2003	1	boiler_temp	61.2	2026-06-21 05:03:16.223
2004	1	boiler_temp	59.0	2026-06-21 05:18:16.223
2005	1	boiler_temp	59.8	2026-06-21 05:33:16.223
2006	1	boiler_temp	60.7	2026-06-21 05:48:16.223
2007	1	boiler_temp	53.5	2026-06-21 06:03:16.223
2008	1	boiler_temp	54.6	2026-06-21 06:18:16.223
2009	1	boiler_temp	53.6	2026-06-21 06:33:16.223
2010	1	boiler_temp	53.8	2026-06-21 06:48:16.223
2011	1	boiler_temp	49.7	2026-06-21 07:03:16.223
2012	1	boiler_temp	51.4	2026-06-21 07:18:16.223
2013	1	boiler_temp	49.1	2026-06-21 07:33:16.223
2014	1	boiler_temp	49.6	2026-06-21 07:48:16.223
2015	1	boiler_temp	44.9	2026-06-21 08:03:16.223
2016	1	boiler_temp	46.2	2026-06-21 08:18:16.223
2017	1	boiler_temp	47.0	2026-06-21 08:33:16.223
2018	1	boiler_temp	47.1	2026-06-21 08:48:16.223
2019	1	boiler_temp	46.3	2026-06-21 09:03:16.223
2020	1	accumulator_temp	70.9	2026-06-14 11:25:07.225
2021	1	accumulator_temp	72.0	2026-06-14 11:40:07.225
2022	1	accumulator_temp	71.0	2026-06-14 11:55:07.225
2023	1	accumulator_temp	69.7	2026-06-14 12:10:07.225
2024	1	accumulator_temp	70.6	2026-06-14 12:25:07.225
2025	1	accumulator_temp	70.2	2026-06-14 12:40:07.225
2026	1	accumulator_temp	70.6	2026-06-14 12:55:07.225
2027	1	accumulator_temp	67.9	2026-06-14 13:10:07.225
2028	1	accumulator_temp	69.0	2026-06-14 13:25:07.225
2029	1	accumulator_temp	67.9	2026-06-14 13:40:07.225
2030	1	accumulator_temp	66.8	2026-06-14 13:55:07.225
2031	1	accumulator_temp	66.3	2026-06-14 14:10:07.225
2032	1	accumulator_temp	65.8	2026-06-14 14:25:07.225
2033	1	accumulator_temp	67.0	2026-06-14 14:40:07.225
2034	1	accumulator_temp	66.5	2026-06-14 14:55:07.225
2035	1	accumulator_temp	65.6	2026-06-14 15:10:07.225
2036	1	accumulator_temp	63.7	2026-06-14 15:25:07.225
2037	1	accumulator_temp	63.1	2026-06-14 15:40:07.225
2038	1	accumulator_temp	63.4	2026-06-14 15:55:07.225
2039	1	accumulator_temp	63.9	2026-06-14 16:10:07.225
2040	1	accumulator_temp	63.4	2026-06-14 16:25:07.225
2041	1	accumulator_temp	64.5	2026-06-14 16:40:07.225
2042	1	accumulator_temp	62.0	2026-06-14 16:55:07.225
2043	1	accumulator_temp	61.7	2026-06-14 17:10:07.225
2044	1	accumulator_temp	63.2	2026-06-14 17:25:07.225
2045	1	accumulator_temp	61.4	2026-06-14 17:40:07.225
2046	1	accumulator_temp	62.3	2026-06-14 17:55:07.225
2047	1	accumulator_temp	60.7	2026-06-14 18:10:07.225
2048	1	accumulator_temp	60.6	2026-06-14 18:25:07.225
2049	1	accumulator_temp	62.2	2026-06-14 18:40:07.225
2050	1	accumulator_temp	62.3	2026-06-14 18:55:07.225
2051	1	accumulator_temp	62.7	2026-06-14 19:10:07.225
2052	1	accumulator_temp	62.6	2026-06-14 19:25:07.225
2053	1	accumulator_temp	63.8	2026-06-14 19:40:07.225
2054	1	accumulator_temp	63.6	2026-06-14 19:55:07.225
2055	1	accumulator_temp	64.2	2026-06-14 20:10:07.225
2056	1	accumulator_temp	62.8	2026-06-14 20:25:07.225
2057	1	accumulator_temp	62.0	2026-06-14 20:40:07.225
2058	1	accumulator_temp	63.6	2026-06-14 20:55:07.225
2059	1	accumulator_temp	64.4	2026-06-14 21:10:07.225
2060	1	accumulator_temp	63.5	2026-06-14 21:25:07.225
2061	1	accumulator_temp	64.9	2026-06-14 21:40:07.225
2062	1	accumulator_temp	65.7	2026-06-14 21:55:07.225
2063	1	accumulator_temp	67.2	2026-06-14 22:10:07.225
2064	1	accumulator_temp	66.4	2026-06-14 22:25:07.225
2065	1	accumulator_temp	64.7	2026-06-14 22:40:07.225
2066	1	accumulator_temp	65.8	2026-06-14 22:55:07.225
2067	1	accumulator_temp	66.8	2026-06-14 23:10:07.225
2068	1	accumulator_temp	66.6	2026-06-14 23:25:07.225
2069	1	accumulator_temp	67.3	2026-06-14 23:40:07.225
2070	1	accumulator_temp	68.3	2026-06-14 23:55:07.225
2071	1	accumulator_temp	70.7	2026-06-15 00:10:07.225
2072	1	accumulator_temp	70.9	2026-06-15 00:25:07.225
2073	1	accumulator_temp	69.9	2026-06-15 00:40:07.225
2074	1	accumulator_temp	70.3	2026-06-15 00:55:07.225
2075	1	accumulator_temp	71.4	2026-06-15 01:10:07.225
2076	1	accumulator_temp	71.9	2026-06-15 01:25:07.225
2077	1	accumulator_temp	71.1	2026-06-15 01:40:07.225
2078	1	accumulator_temp	72.6	2026-06-15 01:55:07.225
2079	1	accumulator_temp	75.0	2026-06-15 02:10:07.225
2080	1	accumulator_temp	75.5	2026-06-15 02:25:07.225
2081	1	accumulator_temp	73.2	2026-06-15 02:40:07.225
2082	1	accumulator_temp	74.7	2026-06-15 02:55:07.225
2083	1	accumulator_temp	76.3	2026-06-15 03:10:07.225
2084	1	accumulator_temp	76.9	2026-06-15 03:25:07.225
2085	1	accumulator_temp	76.2	2026-06-15 03:40:07.225
2086	1	accumulator_temp	75.2	2026-06-15 03:55:07.225
2087	1	accumulator_temp	76.6	2026-06-15 04:10:07.225
2088	1	accumulator_temp	75.9	2026-06-15 04:25:07.225
2089	1	accumulator_temp	77.9	2026-06-15 04:40:07.225
2090	1	accumulator_temp	76.3	2026-06-15 04:55:07.225
2091	1	accumulator_temp	77.9	2026-06-15 05:10:07.225
2092	1	accumulator_temp	77.4	2026-06-15 05:25:07.225
2093	1	accumulator_temp	79.2	2026-06-15 05:40:07.225
2094	1	accumulator_temp	78.3	2026-06-15 05:55:07.225
2095	1	accumulator_temp	78.4	2026-06-15 06:10:07.225
2096	1	accumulator_temp	79.2	2026-06-15 06:25:07.225
2097	1	accumulator_temp	78.5	2026-06-15 06:40:07.225
2098	1	accumulator_temp	77.4	2026-06-15 06:55:07.225
2099	1	accumulator_temp	79.1	2026-06-15 07:10:07.225
2100	1	accumulator_temp	78.9	2026-06-15 07:25:07.225
2101	1	accumulator_temp	78.9	2026-06-15 07:40:07.225
2102	1	accumulator_temp	78.0	2026-06-15 07:55:07.225
2103	1	accumulator_temp	76.4	2026-06-15 08:10:07.225
2104	1	accumulator_temp	78.4	2026-06-15 08:25:07.225
2105	1	accumulator_temp	76.2	2026-06-15 08:40:07.225
2106	1	accumulator_temp	75.6	2026-06-15 08:55:07.225
2107	1	accumulator_temp	74.4	2026-06-15 09:10:07.225
2108	1	accumulator_temp	76.3	2026-06-15 09:25:07.225
2109	1	accumulator_temp	75.0	2026-06-15 09:40:07.225
2110	1	accumulator_temp	76.4	2026-06-15 09:55:07.225
2111	1	accumulator_temp	73.3	2026-06-15 10:10:07.225
2112	1	accumulator_temp	74.9	2026-06-15 10:25:07.225
2113	1	accumulator_temp	75.1	2026-06-15 10:40:07.225
2114	1	accumulator_temp	75.4	2026-06-15 10:55:07.225
2115	1	accumulator_temp	71.2	2026-06-15 11:10:07.225
2116	1	accumulator_temp	73.1	2026-06-15 11:25:07.225
2117	1	accumulator_temp	73.5	2026-06-15 11:40:07.225
2118	1	accumulator_temp	71.1	2026-06-15 11:55:07.225
2119	1	accumulator_temp	70.8	2026-06-15 12:10:07.225
2120	1	accumulator_temp	70.2	2026-06-15 12:25:07.225
2121	1	accumulator_temp	69.8	2026-06-15 12:40:07.225
2122	1	accumulator_temp	71.0	2026-06-15 12:55:07.225
2123	1	accumulator_temp	69.1	2026-06-15 13:10:07.225
2124	1	accumulator_temp	68.3	2026-06-15 13:25:07.225
2125	1	accumulator_temp	69.3	2026-06-15 13:40:07.225
2126	1	accumulator_temp	69.3	2026-06-15 13:55:07.225
2127	1	accumulator_temp	64.8	2026-06-15 14:10:07.225
2128	1	accumulator_temp	66.9	2026-06-15 14:25:07.225
2129	1	accumulator_temp	65.0	2026-06-15 14:40:07.225
2130	1	accumulator_temp	66.6	2026-06-15 14:55:07.225
2131	1	accumulator_temp	65.1	2026-06-15 15:10:07.225
2132	1	accumulator_temp	64.1	2026-06-15 15:25:07.225
2133	1	accumulator_temp	64.5	2026-06-15 15:40:07.225
2134	1	accumulator_temp	63.2	2026-06-15 15:55:07.225
2135	1	accumulator_temp	63.2	2026-06-15 16:10:07.225
2136	1	accumulator_temp	64.4	2026-06-15 16:25:07.225
2137	1	accumulator_temp	62.1	2026-06-15 16:40:07.225
2138	1	accumulator_temp	62.3	2026-06-15 16:55:07.225
2139	1	accumulator_temp	61.2	2026-06-15 17:10:07.225
2140	1	accumulator_temp	63.0	2026-06-15 17:25:07.225
2141	1	accumulator_temp	62.9	2026-06-15 17:40:07.225
2142	1	accumulator_temp	63.7	2026-06-15 17:55:07.225
2143	1	accumulator_temp	61.4	2026-06-15 18:10:07.225
2144	1	accumulator_temp	61.1	2026-06-15 18:25:07.225
2145	1	accumulator_temp	63.3	2026-06-15 18:40:07.225
2146	1	accumulator_temp	62.2	2026-06-15 18:55:07.225
2147	1	accumulator_temp	62.3	2026-06-15 19:10:07.225
2148	1	accumulator_temp	63.6	2026-06-15 19:25:07.225
2149	1	accumulator_temp	63.0	2026-06-15 19:40:07.225
2150	1	accumulator_temp	62.4	2026-06-15 19:55:07.225
2151	1	accumulator_temp	63.5	2026-06-15 20:10:07.225
2152	1	accumulator_temp	62.9	2026-06-15 20:25:07.225
2153	1	accumulator_temp	62.8	2026-06-15 20:40:07.225
2154	1	accumulator_temp	64.2	2026-06-15 20:55:07.225
2155	1	accumulator_temp	64.3	2026-06-15 21:10:07.225
2156	1	accumulator_temp	63.6	2026-06-15 21:25:07.225
2157	1	accumulator_temp	63.9	2026-06-15 21:40:07.225
2158	1	accumulator_temp	64.5	2026-06-15 21:55:07.225
2159	1	accumulator_temp	66.7	2026-06-15 22:10:07.225
2160	1	accumulator_temp	65.9	2026-06-15 22:25:07.225
2161	1	accumulator_temp	67.5	2026-06-15 22:40:07.225
2162	1	accumulator_temp	64.7	2026-06-15 22:55:07.225
2163	1	accumulator_temp	68.3	2026-06-15 23:10:07.225
2164	1	accumulator_temp	68.9	2026-06-15 23:25:07.225
2165	1	accumulator_temp	68.3	2026-06-15 23:40:07.225
2166	1	accumulator_temp	67.3	2026-06-15 23:55:07.225
2167	1	accumulator_temp	70.8	2026-06-16 00:10:07.225
2168	1	accumulator_temp	70.4	2026-06-16 00:25:07.225
2169	1	accumulator_temp	69.5	2026-06-16 00:40:07.225
2170	1	accumulator_temp	68.8	2026-06-16 00:55:07.225
2171	1	accumulator_temp	71.8	2026-06-16 01:10:07.225
2172	1	accumulator_temp	72.6	2026-06-16 01:25:07.225
2173	1	accumulator_temp	71.6	2026-06-16 01:40:07.225
2174	1	accumulator_temp	72.4	2026-06-16 01:55:07.225
2175	1	accumulator_temp	74.4	2026-06-16 02:10:07.225
2176	1	accumulator_temp	75.1	2026-06-16 02:25:07.225
2177	1	accumulator_temp	73.5	2026-06-16 02:40:07.225
2178	1	accumulator_temp	74.1	2026-06-16 02:55:07.225
2179	1	accumulator_temp	74.5	2026-06-16 03:10:07.225
2180	1	accumulator_temp	77.1	2026-06-16 03:25:07.225
2181	1	accumulator_temp	75.2	2026-06-16 03:40:07.225
2182	1	accumulator_temp	75.9	2026-06-16 03:55:07.225
2183	1	accumulator_temp	77.0	2026-06-16 04:10:07.225
2184	1	accumulator_temp	77.5	2026-06-16 04:25:07.225
2185	1	accumulator_temp	77.4	2026-06-16 04:40:07.225
2186	1	accumulator_temp	75.9	2026-06-16 04:55:07.225
2187	1	accumulator_temp	78.8	2026-06-16 05:10:07.225
2188	1	accumulator_temp	79.0	2026-06-16 05:25:07.225
2189	1	accumulator_temp	77.2	2026-06-16 05:40:07.225
2190	1	accumulator_temp	78.1	2026-06-16 05:55:07.225
2191	1	accumulator_temp	79.0	2026-06-16 06:10:07.225
2192	1	accumulator_temp	76.9	2026-06-16 06:25:07.225
2193	1	accumulator_temp	78.0	2026-06-16 06:40:07.225
2194	1	accumulator_temp	76.8	2026-06-16 06:55:07.225
2195	1	accumulator_temp	77.6	2026-06-16 07:10:07.225
2196	1	accumulator_temp	77.1	2026-06-16 07:25:07.225
2197	1	accumulator_temp	78.3	2026-06-16 07:40:07.225
2198	1	accumulator_temp	78.5	2026-06-16 07:55:07.225
2199	1	accumulator_temp	78.2	2026-06-16 08:10:07.225
2200	1	accumulator_temp	76.9	2026-06-16 08:25:07.225
2201	1	accumulator_temp	77.3	2026-06-16 08:40:07.225
2202	1	accumulator_temp	75.6	2026-06-16 08:55:07.225
2203	1	accumulator_temp	75.0	2026-06-16 09:10:07.225
2204	1	accumulator_temp	75.3	2026-06-16 09:25:07.225
2205	1	accumulator_temp	75.4	2026-06-16 09:40:07.225
2206	1	accumulator_temp	77.1	2026-06-16 09:55:07.225
2207	1	accumulator_temp	74.6	2026-06-16 10:10:07.225
2208	1	accumulator_temp	73.2	2026-06-16 10:25:07.225
2209	1	accumulator_temp	73.9	2026-06-16 10:40:07.225
2210	1	accumulator_temp	75.4	2026-06-16 10:55:07.225
2211	1	accumulator_temp	73.0	2026-06-16 11:10:07.225
2212	1	accumulator_temp	72.6	2026-06-16 11:25:07.225
2213	1	accumulator_temp	72.8	2026-06-16 11:40:07.225
2214	1	accumulator_temp	71.1	2026-06-16 11:55:07.225
2215	1	accumulator_temp	70.4	2026-06-16 12:10:07.225
2216	1	accumulator_temp	68.7	2026-06-16 12:25:07.225
2217	1	accumulator_temp	68.5	2026-06-16 12:40:07.225
2218	1	accumulator_temp	69.5	2026-06-16 12:55:07.225
2219	1	accumulator_temp	68.0	2026-06-16 13:10:07.225
2220	1	accumulator_temp	66.7	2026-06-16 13:25:07.225
2221	1	accumulator_temp	68.8	2026-06-16 13:40:07.225
2222	1	accumulator_temp	69.0	2026-06-16 13:55:07.225
2223	1	accumulator_temp	66.2	2026-06-16 14:10:07.225
2224	1	accumulator_temp	66.2	2026-06-16 14:25:07.225
2225	1	accumulator_temp	66.2	2026-06-16 14:40:07.225
2226	1	accumulator_temp	66.9	2026-06-16 14:55:07.225
2227	1	accumulator_temp	63.9	2026-06-16 15:10:07.225
2228	1	accumulator_temp	63.1	2026-06-16 15:25:07.225
2229	1	accumulator_temp	64.9	2026-06-16 15:40:07.225
2230	1	accumulator_temp	65.7	2026-06-16 15:55:07.225
2231	1	accumulator_temp	63.6	2026-06-16 16:10:07.225
2232	1	accumulator_temp	63.2	2026-06-16 16:25:07.225
2233	1	accumulator_temp	63.7	2026-06-16 16:40:07.225
2234	1	accumulator_temp	62.6	2026-06-16 16:55:07.225
2235	1	accumulator_temp	63.6	2026-06-16 17:10:07.225
2236	1	accumulator_temp	62.3	2026-06-16 17:25:07.225
2237	1	accumulator_temp	63.1	2026-06-16 17:40:07.225
2238	1	accumulator_temp	62.5	2026-06-16 17:55:07.225
2239	1	accumulator_temp	63.1	2026-06-16 18:10:07.225
2240	1	accumulator_temp	60.5	2026-06-16 18:25:07.225
2241	1	accumulator_temp	60.7	2026-06-16 18:40:07.225
2242	1	accumulator_temp	62.8	2026-06-16 18:55:07.225
2243	1	accumulator_temp	63.7	2026-06-16 19:10:07.225
2244	1	accumulator_temp	61.3	2026-06-16 19:25:07.225
2245	1	accumulator_temp	63.6	2026-06-16 19:40:07.225
2246	1	accumulator_temp	63.2	2026-06-16 19:55:07.225
2247	1	accumulator_temp	61.6	2026-06-16 20:10:07.225
2248	1	accumulator_temp	62.5	2026-06-16 20:25:07.225
2249	1	accumulator_temp	61.9	2026-06-16 20:40:07.225
2250	1	accumulator_temp	63.3	2026-06-16 20:55:07.225
2251	1	accumulator_temp	64.6	2026-06-16 21:10:07.225
2252	1	accumulator_temp	63.6	2026-06-16 21:25:07.225
2253	1	accumulator_temp	65.2	2026-06-16 21:40:07.225
2254	1	accumulator_temp	63.3	2026-06-16 21:55:07.225
2255	1	accumulator_temp	66.0	2026-06-16 22:10:07.225
2256	1	accumulator_temp	66.1	2026-06-16 22:25:07.225
2257	1	accumulator_temp	66.0	2026-06-16 22:40:07.225
2258	1	accumulator_temp	66.9	2026-06-16 22:55:07.225
2259	1	accumulator_temp	66.7	2026-06-16 23:10:07.225
2260	1	accumulator_temp	69.1	2026-06-16 23:25:07.225
2261	1	accumulator_temp	67.3	2026-06-16 23:40:07.225
2262	1	accumulator_temp	68.8	2026-06-16 23:55:07.225
2263	1	accumulator_temp	70.2	2026-06-17 00:10:07.225
2264	1	accumulator_temp	68.6	2026-06-17 00:25:07.225
2265	1	accumulator_temp	71.2	2026-06-17 00:40:07.225
2266	1	accumulator_temp	71.5	2026-06-17 00:55:07.225
2267	1	accumulator_temp	72.8	2026-06-17 01:10:07.225
2268	1	accumulator_temp	73.4	2026-06-17 01:25:07.225
2269	1	accumulator_temp	73.1	2026-06-17 01:40:07.225
2270	1	accumulator_temp	70.7	2026-06-17 01:55:07.225
2271	1	accumulator_temp	74.5	2026-06-17 02:10:07.225
2272	1	accumulator_temp	73.4	2026-06-17 02:25:07.225
2273	1	accumulator_temp	74.5	2026-06-17 02:40:07.225
2274	1	accumulator_temp	75.4	2026-06-17 02:55:07.225
2275	1	accumulator_temp	74.2	2026-06-17 03:10:07.225
2276	1	accumulator_temp	75.8	2026-06-17 03:25:07.225
2277	1	accumulator_temp	75.5	2026-06-17 03:40:07.225
2278	1	accumulator_temp	76.1	2026-06-17 03:55:07.225
2279	1	accumulator_temp	76.8	2026-06-17 04:10:07.225
2280	1	accumulator_temp	77.0	2026-06-17 04:25:07.225
2281	1	accumulator_temp	77.6	2026-06-17 04:40:07.225
2282	1	accumulator_temp	76.9	2026-06-17 04:55:07.225
2283	1	accumulator_temp	79.1	2026-06-17 05:10:07.225
2284	1	accumulator_temp	76.3	2026-06-17 05:25:07.225
2285	1	accumulator_temp	76.4	2026-06-17 05:40:07.225
2286	1	accumulator_temp	76.4	2026-06-17 05:55:07.225
2287	1	accumulator_temp	77.6	2026-06-17 06:10:07.225
2288	1	accumulator_temp	77.0	2026-06-17 06:25:07.225
2289	1	accumulator_temp	76.8	2026-06-17 06:40:07.225
2290	1	accumulator_temp	76.9	2026-06-17 06:55:07.225
2291	1	accumulator_temp	76.8	2026-06-17 07:10:07.225
2292	1	accumulator_temp	79.0	2026-06-17 07:25:07.225
2293	1	accumulator_temp	78.2	2026-06-17 07:40:07.225
2294	1	accumulator_temp	77.0	2026-06-17 07:55:07.225
2295	1	accumulator_temp	76.5	2026-06-17 08:10:07.225
2296	1	accumulator_temp	75.7	2026-06-17 08:25:07.225
2297	1	accumulator_temp	77.1	2026-06-17 08:40:07.225
2298	1	accumulator_temp	76.8	2026-06-17 08:55:07.225
2299	1	accumulator_temp	76.5	2026-06-17 09:10:07.225
2300	1	accumulator_temp	76.4	2026-06-17 09:25:07.225
2301	1	accumulator_temp	76.8	2026-06-17 09:40:07.225
2302	1	accumulator_temp	76.3	2026-06-17 09:55:07.225
2303	1	accumulator_temp	74.3	2026-06-17 10:10:07.225
2304	1	accumulator_temp	75.2	2026-06-17 10:25:07.225
2305	1	accumulator_temp	73.6	2026-06-17 10:40:07.225
2306	1	accumulator_temp	74.1	2026-06-17 10:55:07.225
2307	1	accumulator_temp	71.0	2026-06-17 11:10:07.225
2308	1	accumulator_temp	72.7	2026-06-17 11:25:07.225
2309	1	accumulator_temp	71.6	2026-06-17 11:40:07.225
2310	1	accumulator_temp	71.8	2026-06-17 11:55:07.225
2311	1	accumulator_temp	68.9	2026-06-17 12:10:07.225
2312	1	accumulator_temp	70.2	2026-06-17 12:25:07.225
2313	1	accumulator_temp	68.9	2026-06-17 12:40:07.225
2314	1	accumulator_temp	70.1	2026-06-17 12:55:07.225
2315	1	accumulator_temp	68.5	2026-06-17 13:10:07.225
2316	1	accumulator_temp	68.3	2026-06-17 13:25:07.225
2317	1	accumulator_temp	69.4	2026-06-17 13:40:07.225
2318	1	accumulator_temp	68.0	2026-06-17 13:55:07.225
2319	1	accumulator_temp	66.9	2026-06-17 14:10:07.225
2320	1	accumulator_temp	66.2	2026-06-17 14:25:07.225
2321	1	accumulator_temp	67.0	2026-06-17 14:40:07.225
2322	1	accumulator_temp	67.0	2026-06-17 14:55:07.225
2323	1	accumulator_temp	65.5	2026-06-17 15:10:07.225
2324	1	accumulator_temp	64.1	2026-06-17 15:25:07.225
2325	1	accumulator_temp	64.5	2026-06-17 15:40:07.225
2326	1	accumulator_temp	63.0	2026-06-17 15:55:07.225
2327	1	accumulator_temp	62.5	2026-06-17 16:10:07.225
2328	1	accumulator_temp	64.1	2026-06-17 16:25:07.225
2329	1	accumulator_temp	63.5	2026-06-17 16:40:07.225
2330	1	accumulator_temp	64.5	2026-06-17 16:55:07.225
2331	1	accumulator_temp	63.7	2026-06-17 17:10:07.225
2332	1	accumulator_temp	62.6	2026-06-17 17:25:07.225
2333	1	accumulator_temp	62.6	2026-06-17 17:40:07.225
2334	1	accumulator_temp	63.0	2026-06-17 17:55:07.225
2335	1	accumulator_temp	62.6	2026-06-17 18:10:07.225
2336	1	accumulator_temp	62.6	2026-06-17 18:25:07.225
2337	1	accumulator_temp	61.6	2026-06-17 18:40:07.225
2338	1	accumulator_temp	61.1	2026-06-17 18:55:07.225
2339	1	accumulator_temp	63.3	2026-06-17 19:10:07.225
2340	1	accumulator_temp	61.8	2026-06-17 19:25:07.225
2341	1	accumulator_temp	62.0	2026-06-17 19:40:07.225
2342	1	accumulator_temp	62.6	2026-06-17 19:55:07.225
2343	1	accumulator_temp	63.5	2026-06-17 20:10:07.225
2344	1	accumulator_temp	62.7	2026-06-17 20:25:07.225
2345	1	accumulator_temp	64.3	2026-06-17 20:40:07.225
2346	1	accumulator_temp	64.4	2026-06-17 20:55:07.225
2347	1	accumulator_temp	63.2	2026-06-17 21:10:07.225
2348	1	accumulator_temp	63.4	2026-06-17 21:25:07.225
2349	1	accumulator_temp	64.3	2026-06-17 21:40:07.225
2350	1	accumulator_temp	63.3	2026-06-17 21:55:07.225
2351	1	accumulator_temp	65.3	2026-06-17 22:10:07.225
2352	1	accumulator_temp	65.4	2026-06-17 22:25:07.225
2353	1	accumulator_temp	66.4	2026-06-17 22:40:07.225
2354	1	accumulator_temp	64.6	2026-06-17 22:55:07.225
2355	1	accumulator_temp	66.9	2026-06-17 23:10:07.225
2356	1	accumulator_temp	67.4	2026-06-17 23:25:07.225
2357	1	accumulator_temp	69.1	2026-06-17 23:40:07.225
2358	1	accumulator_temp	69.3	2026-06-17 23:55:07.225
2359	1	accumulator_temp	68.7	2026-06-18 00:10:07.225
2360	1	accumulator_temp	68.7	2026-06-18 00:25:07.225
2361	1	accumulator_temp	70.0	2026-06-18 00:40:07.225
2362	1	accumulator_temp	68.6	2026-06-18 00:55:07.225
2363	1	accumulator_temp	73.3	2026-06-18 01:10:07.225
2364	1	accumulator_temp	71.2	2026-06-18 01:25:07.225
2365	1	accumulator_temp	72.0	2026-06-18 01:40:07.225
2366	1	accumulator_temp	73.3	2026-06-18 01:55:07.225
2367	1	accumulator_temp	73.5	2026-06-18 02:10:07.225
2368	1	accumulator_temp	74.8	2026-06-18 02:25:07.225
2369	1	accumulator_temp	73.0	2026-06-18 02:40:07.225
2370	1	accumulator_temp	73.1	2026-06-18 02:55:07.225
2371	1	accumulator_temp	74.2	2026-06-18 03:10:07.225
2372	1	accumulator_temp	74.4	2026-06-18 03:25:07.225
2373	1	accumulator_temp	74.9	2026-06-18 03:40:07.225
2374	1	accumulator_temp	76.9	2026-06-18 03:55:07.225
2375	1	accumulator_temp	76.8	2026-06-18 04:10:07.225
2376	1	accumulator_temp	77.7	2026-06-18 04:25:07.225
2377	1	accumulator_temp	77.0	2026-06-18 04:40:07.225
2378	1	accumulator_temp	78.0	2026-06-18 04:55:07.225
2379	1	accumulator_temp	78.0	2026-06-18 05:10:07.225
2380	1	accumulator_temp	77.4	2026-06-18 05:25:07.225
2381	1	accumulator_temp	76.3	2026-06-18 05:40:07.225
2382	1	accumulator_temp	77.8	2026-06-18 05:55:07.225
2383	1	accumulator_temp	79.1	2026-06-18 06:10:07.225
2384	1	accumulator_temp	78.5	2026-06-18 06:25:07.225
2385	1	accumulator_temp	77.3	2026-06-18 06:40:07.225
2386	1	accumulator_temp	77.7	2026-06-18 06:55:07.225
2387	1	accumulator_temp	76.5	2026-06-18 07:10:07.225
2388	1	accumulator_temp	77.2	2026-06-18 07:25:07.225
2389	1	accumulator_temp	77.6	2026-06-18 07:40:07.225
2390	1	accumulator_temp	78.1	2026-06-18 07:55:07.225
2391	1	accumulator_temp	76.3	2026-06-18 08:10:07.225
2392	1	accumulator_temp	77.2	2026-06-18 08:25:07.225
2393	1	accumulator_temp	76.2	2026-06-18 08:40:07.225
2394	1	accumulator_temp	75.5	2026-06-18 08:55:07.225
2395	1	accumulator_temp	75.9	2026-06-18 09:10:07.225
2396	1	accumulator_temp	74.5	2026-06-18 09:25:07.225
2397	1	accumulator_temp	75.9	2026-06-18 09:40:07.225
2398	1	accumulator_temp	75.6	2026-06-18 09:55:07.225
2399	1	accumulator_temp	74.1	2026-06-18 10:10:07.225
2400	1	accumulator_temp	73.8	2026-06-18 10:25:07.225
2401	1	accumulator_temp	75.2	2026-06-18 10:40:07.225
2402	1	accumulator_temp	73.0	2026-06-18 10:55:07.225
2403	1	accumulator_temp	72.7	2026-06-18 11:10:07.225
2404	1	accumulator_temp	73.1	2026-06-18 11:25:07.225
2405	1	accumulator_temp	73.2	2026-06-18 11:40:07.225
2406	1	accumulator_temp	73.5	2026-06-18 11:55:07.225
2407	1	accumulator_temp	69.4	2026-06-18 12:10:07.225
2408	1	accumulator_temp	69.5	2026-06-18 12:25:07.225
2409	1	accumulator_temp	68.8	2026-06-18 12:40:07.225
2410	1	accumulator_temp	70.9	2026-06-18 12:55:07.225
2411	1	accumulator_temp	68.7	2026-06-18 13:10:07.225
2412	1	accumulator_temp	66.7	2026-06-18 13:25:07.225
2413	1	accumulator_temp	67.7	2026-06-18 13:40:07.225
2414	1	accumulator_temp	66.8	2026-06-18 13:55:07.225
2415	1	accumulator_temp	65.0	2026-06-18 14:10:07.225
2416	1	accumulator_temp	65.2	2026-06-18 14:25:07.225
2417	1	accumulator_temp	66.5	2026-06-18 14:40:07.225
2418	1	accumulator_temp	65.7	2026-06-18 14:55:07.225
2419	1	accumulator_temp	63.4	2026-06-18 15:10:07.225
2420	1	accumulator_temp	64.4	2026-06-18 15:25:07.225
2421	1	accumulator_temp	65.8	2026-06-18 15:40:07.225
2422	1	accumulator_temp	63.0	2026-06-18 15:55:07.225
2423	1	accumulator_temp	62.0	2026-06-18 16:10:07.225
2424	1	accumulator_temp	64.1	2026-06-18 16:25:07.225
2425	1	accumulator_temp	62.6	2026-06-18 16:40:07.225
2426	1	accumulator_temp	62.3	2026-06-18 16:55:07.225
2427	1	accumulator_temp	61.1	2026-06-18 17:10:07.225
2428	1	accumulator_temp	62.9	2026-06-18 17:25:07.225
2429	1	accumulator_temp	61.3	2026-06-18 17:40:07.225
2430	1	accumulator_temp	62.4	2026-06-18 17:55:07.225
2431	1	accumulator_temp	62.8	2026-06-18 18:10:07.225
2432	1	accumulator_temp	60.6	2026-06-18 18:25:07.225
2433	1	accumulator_temp	61.1	2026-06-18 18:40:07.225
2434	1	accumulator_temp	61.4	2026-06-18 18:55:07.225
2435	1	accumulator_temp	63.7	2026-06-18 19:10:07.225
2436	1	accumulator_temp	60.9	2026-06-18 19:25:07.225
2437	1	accumulator_temp	61.7	2026-06-18 19:40:07.225
2438	1	accumulator_temp	61.1	2026-06-18 19:55:07.225
2439	1	accumulator_temp	62.5	2026-06-18 20:10:07.225
2440	1	accumulator_temp	64.0	2026-06-18 20:25:07.225
2441	1	accumulator_temp	62.6	2026-06-18 20:40:07.225
2442	1	accumulator_temp	62.4	2026-06-18 20:55:07.225
2443	1	accumulator_temp	63.5	2026-06-18 21:10:07.225
2444	1	accumulator_temp	63.8	2026-06-18 21:25:07.225
2445	1	accumulator_temp	65.0	2026-06-18 21:40:07.225
2446	1	accumulator_temp	64.3	2026-06-18 21:55:07.225
2447	1	accumulator_temp	67.4	2026-06-18 22:10:07.225
2448	1	accumulator_temp	65.0	2026-06-18 22:25:07.225
2449	1	accumulator_temp	66.8	2026-06-18 22:40:07.225
2450	1	accumulator_temp	66.6	2026-06-18 22:55:07.225
2451	1	accumulator_temp	67.1	2026-06-18 23:10:07.225
2452	1	accumulator_temp	67.8	2026-06-18 23:25:07.225
2453	1	accumulator_temp	67.0	2026-06-18 23:40:07.225
2454	1	accumulator_temp	68.6	2026-06-18 23:55:07.225
2455	1	accumulator_temp	70.2	2026-06-19 00:10:07.225
2456	1	accumulator_temp	69.3	2026-06-19 00:25:07.225
2457	1	accumulator_temp	68.9	2026-06-19 00:40:07.225
2458	1	accumulator_temp	69.7	2026-06-19 00:55:07.225
2459	1	accumulator_temp	72.4	2026-06-19 01:10:07.225
2460	1	accumulator_temp	72.8	2026-06-19 01:25:07.225
2461	1	accumulator_temp	71.5	2026-06-19 01:40:07.225
2462	1	accumulator_temp	73.0	2026-06-19 01:55:07.225
2463	1	accumulator_temp	73.0	2026-06-19 02:10:07.225
2464	1	accumulator_temp	75.1	2026-06-19 02:25:07.225
2465	1	accumulator_temp	74.0	2026-06-19 02:40:07.225
2466	1	accumulator_temp	73.5	2026-06-19 02:55:07.225
2467	1	accumulator_temp	76.1	2026-06-19 03:10:07.225
2468	1	accumulator_temp	75.3	2026-06-19 03:25:07.225
2469	1	accumulator_temp	75.6	2026-06-19 03:40:07.225
2470	1	accumulator_temp	74.3	2026-06-19 03:55:07.225
2471	1	accumulator_temp	75.6	2026-06-19 04:10:07.225
2472	1	accumulator_temp	76.2	2026-06-19 04:25:07.225
2473	1	accumulator_temp	75.8	2026-06-19 04:40:07.225
2474	1	accumulator_temp	76.4	2026-06-19 04:55:07.225
2475	1	accumulator_temp	76.7	2026-06-19 05:10:07.225
2476	1	accumulator_temp	77.9	2026-06-19 05:25:07.225
2477	1	accumulator_temp	76.3	2026-06-19 05:40:07.225
2478	1	accumulator_temp	77.3	2026-06-19 05:55:07.225
2479	1	accumulator_temp	77.1	2026-06-19 06:10:07.225
2480	1	accumulator_temp	78.5	2026-06-19 06:25:07.225
2481	1	accumulator_temp	78.8	2026-06-19 06:40:07.225
2482	1	accumulator_temp	76.9	2026-06-19 06:55:07.225
2483	1	accumulator_temp	76.4	2026-06-19 07:10:07.225
2484	1	accumulator_temp	78.2	2026-06-19 07:25:07.225
2485	1	accumulator_temp	79.2	2026-06-19 07:40:07.225
2486	1	accumulator_temp	76.4	2026-06-19 07:55:07.225
2487	1	accumulator_temp	76.3	2026-06-19 08:10:07.225
2488	1	accumulator_temp	77.6	2026-06-19 08:25:07.225
2489	1	accumulator_temp	75.5	2026-06-19 08:40:07.225
2490	1	accumulator_temp	76.2	2026-06-19 08:55:07.225
2491	1	accumulator_temp	74.2	2026-06-19 09:10:07.225
2492	1	accumulator_temp	74.6	2026-06-19 09:25:07.225
2493	1	accumulator_temp	76.2	2026-06-19 09:40:07.225
2494	1	accumulator_temp	74.8	2026-06-19 09:55:07.225
2495	1	accumulator_temp	72.9	2026-06-19 10:10:07.225
2496	1	accumulator_temp	74.0	2026-06-19 10:25:07.225
2497	1	accumulator_temp	74.2	2026-06-19 10:40:07.225
2498	1	accumulator_temp	74.4	2026-06-19 10:55:07.225
2499	1	accumulator_temp	70.8	2026-06-19 11:10:07.225
2500	1	accumulator_temp	73.2	2026-06-19 11:25:07.225
2501	1	accumulator_temp	72.5	2026-06-19 11:40:07.225
2502	1	accumulator_temp	71.7	2026-06-19 11:55:07.225
2503	1	accumulator_temp	69.5	2026-06-19 12:10:07.225
2504	1	accumulator_temp	70.3	2026-06-19 12:25:07.225
2505	1	accumulator_temp	68.9	2026-06-19 12:40:07.225
2506	1	accumulator_temp	68.5	2026-06-19 12:55:07.225
2507	1	accumulator_temp	69.3	2026-06-19 13:10:07.225
2508	1	accumulator_temp	69.0	2026-06-19 13:25:07.225
2509	1	accumulator_temp	69.0	2026-06-19 13:40:07.225
2510	1	accumulator_temp	66.7	2026-06-19 13:55:07.225
2511	1	accumulator_temp	64.6	2026-06-19 14:10:07.225
2512	1	accumulator_temp	67.5	2026-06-19 14:25:07.225
2513	1	accumulator_temp	66.3	2026-06-19 14:40:07.225
2514	1	accumulator_temp	67.1	2026-06-19 14:55:07.225
2515	1	accumulator_temp	64.7	2026-06-19 15:10:07.225
2516	1	accumulator_temp	63.7	2026-06-19 15:25:07.225
2517	1	accumulator_temp	63.3	2026-06-19 15:40:07.225
2518	1	accumulator_temp	62.9	2026-06-19 15:55:07.225
2519	1	accumulator_temp	63.5	2026-06-19 16:10:07.225
2520	1	accumulator_temp	63.7	2026-06-19 16:25:07.225
2521	1	accumulator_temp	62.1	2026-06-19 16:40:07.225
2522	1	accumulator_temp	63.3	2026-06-19 16:55:07.225
2523	1	accumulator_temp	63.4	2026-06-19 17:10:07.225
2524	1	accumulator_temp	62.0	2026-06-19 17:25:07.225
2525	1	accumulator_temp	61.6	2026-06-19 17:40:07.225
2526	1	accumulator_temp	62.2	2026-06-19 17:55:07.225
2527	1	accumulator_temp	62.7	2026-06-19 18:10:07.225
2528	1	accumulator_temp	62.5	2026-06-19 18:25:07.225
2529	1	accumulator_temp	62.3	2026-06-19 18:40:07.225
2530	1	accumulator_temp	61.5	2026-06-19 18:55:07.225
2531	1	accumulator_temp	63.2	2026-06-19 19:10:07.225
2532	1	accumulator_temp	63.4	2026-06-19 19:25:07.225
2533	1	accumulator_temp	62.1	2026-06-19 19:40:07.225
2534	1	accumulator_temp	62.6	2026-06-19 19:55:07.225
2535	1	accumulator_temp	61.7	2026-06-19 20:10:07.225
2536	1	accumulator_temp	63.1	2026-06-19 20:25:07.225
2537	1	accumulator_temp	64.6	2026-06-19 20:40:07.225
2538	1	accumulator_temp	63.7	2026-06-19 20:55:07.225
2539	1	accumulator_temp	65.6	2026-06-19 21:10:07.225
2540	1	accumulator_temp	65.2	2026-06-19 21:25:07.225
2541	1	accumulator_temp	63.0	2026-06-19 21:40:07.225
2542	1	accumulator_temp	65.7	2026-06-19 21:55:07.225
2543	1	accumulator_temp	64.7	2026-06-19 22:10:07.225
2544	1	accumulator_temp	66.3	2026-06-19 22:25:07.225
2545	1	accumulator_temp	67.1	2026-06-19 22:40:07.225
2546	1	accumulator_temp	65.1	2026-06-19 22:55:07.225
2547	1	accumulator_temp	66.7	2026-06-19 23:10:07.225
2548	1	accumulator_temp	67.3	2026-06-19 23:25:07.225
2549	1	accumulator_temp	67.9	2026-06-19 23:40:07.225
2550	1	accumulator_temp	68.7	2026-06-19 23:55:07.225
2551	1	accumulator_temp	70.2	2026-06-20 00:10:07.225
2552	1	accumulator_temp	70.3	2026-06-20 00:25:07.225
2553	1	accumulator_temp	70.1	2026-06-20 00:40:07.225
2554	1	accumulator_temp	69.4	2026-06-20 00:55:07.225
2555	1	accumulator_temp	73.2	2026-06-20 01:10:07.225
2556	1	accumulator_temp	72.8	2026-06-20 01:25:07.225
2557	1	accumulator_temp	71.8	2026-06-20 01:40:07.225
2558	1	accumulator_temp	73.3	2026-06-20 01:55:07.225
2559	1	accumulator_temp	72.8	2026-06-20 02:10:07.225
2560	1	accumulator_temp	74.3	2026-06-20 02:25:07.225
2561	1	accumulator_temp	73.8	2026-06-20 02:40:07.225
2562	1	accumulator_temp	73.6	2026-06-20 02:55:07.225
2563	1	accumulator_temp	75.6	2026-06-20 03:10:07.225
2564	1	accumulator_temp	75.9	2026-06-20 03:25:07.225
2565	1	accumulator_temp	76.4	2026-06-20 03:40:07.225
2566	1	accumulator_temp	74.3	2026-06-20 03:55:07.225
2567	1	accumulator_temp	75.7	2026-06-20 04:10:07.225
2568	1	accumulator_temp	75.8	2026-06-20 04:25:07.225
2569	1	accumulator_temp	76.8	2026-06-20 04:40:07.225
2570	1	accumulator_temp	77.7	2026-06-20 04:55:07.225
2571	1	accumulator_temp	78.1	2026-06-20 05:10:07.225
2572	1	accumulator_temp	78.4	2026-06-20 05:25:07.225
2573	1	accumulator_temp	76.4	2026-06-20 05:40:07.225
2574	1	accumulator_temp	78.3	2026-06-20 05:55:07.225
2575	1	accumulator_temp	78.3	2026-06-20 06:10:07.225
2576	1	accumulator_temp	78.1	2026-06-20 06:25:07.225
2577	1	accumulator_temp	79.5	2026-06-20 06:40:07.225
2578	1	accumulator_temp	77.7	2026-06-20 06:55:07.225
2579	1	accumulator_temp	78.0	2026-06-20 07:10:07.225
2580	1	accumulator_temp	77.2	2026-06-20 07:25:07.225
2581	1	accumulator_temp	76.5	2026-06-20 07:40:07.225
2582	1	accumulator_temp	77.3	2026-06-20 07:55:07.225
2583	1	accumulator_temp	76.1	2026-06-20 08:10:07.225
2584	1	accumulator_temp	76.6	2026-06-20 08:25:07.225
2585	1	accumulator_temp	76.2	2026-06-20 08:40:07.225
2586	1	accumulator_temp	77.3	2026-06-20 08:55:07.225
2587	1	accumulator_temp	74.2	2026-06-20 09:10:07.225
2588	1	accumulator_temp	74.2	2026-06-20 09:25:07.225
2589	1	accumulator_temp	74.3	2026-06-20 09:40:07.225
2590	1	accumulator_temp	75.9	2026-06-20 09:55:07.225
2591	1	accumulator_temp	74.1	2026-06-20 10:10:07.225
2592	1	accumulator_temp	73.7	2026-06-20 10:25:07.225
2593	1	accumulator_temp	74.3	2026-06-20 10:40:07.225
2594	1	accumulator_temp	75.0	2026-06-20 10:55:07.225
2595	1	accumulator_temp	71.0	2026-06-20 11:10:07.225
2596	1	accumulator_temp	71.8	2026-06-20 11:25:07.225
2597	1	accumulator_temp	73.2	2026-06-20 11:40:07.225
2598	1	accumulator_temp	71.3	2026-06-20 11:55:07.225
2599	1	accumulator_temp	69.7	2026-06-20 12:10:07.225
2600	1	accumulator_temp	70.8	2026-06-20 12:25:07.225
2601	1	accumulator_temp	71.0	2026-06-20 12:40:07.225
2602	1	accumulator_temp	70.4	2026-06-20 12:55:07.225
2603	1	accumulator_temp	67.4	2026-06-20 13:10:07.225
2604	1	accumulator_temp	67.1	2026-06-20 13:25:07.225
2605	1	accumulator_temp	68.7	2026-06-20 13:40:07.225
2606	1	accumulator_temp	67.4	2026-06-20 13:55:07.225
2607	1	accumulator_temp	66.9	2026-06-20 14:10:07.225
2608	1	accumulator_temp	65.4	2026-06-20 14:25:07.225
2609	1	accumulator_temp	65.8	2026-06-20 14:40:07.225
2610	1	accumulator_temp	66.6	2026-06-20 14:55:07.225
2611	1	accumulator_temp	63.6	2026-06-20 15:10:07.225
2612	1	accumulator_temp	64.1	2026-06-20 15:25:07.225
2613	1	accumulator_temp	64.4	2026-06-20 15:40:07.225
2614	1	accumulator_temp	65.7	2026-06-20 15:55:07.225
2615	1	accumulator_temp	62.0	2026-06-20 16:10:07.225
2616	1	accumulator_temp	61.7	2026-06-20 16:25:07.225
2617	1	accumulator_temp	62.7	2026-06-20 16:40:07.225
2618	1	accumulator_temp	62.0	2026-06-20 16:55:07.225
2619	1	accumulator_temp	62.2	2026-06-20 17:10:07.225
2620	1	accumulator_temp	62.8	2026-06-20 17:25:07.225
2621	1	accumulator_temp	60.8	2026-06-20 17:40:07.225
2622	1	accumulator_temp	63.3	2026-06-20 17:55:07.225
2623	1	accumulator_temp	63.3	2026-06-20 18:10:07.225
2624	1	accumulator_temp	62.2	2026-06-20 18:25:07.225
2625	1	accumulator_temp	62.2	2026-06-20 18:40:07.225
2626	1	accumulator_temp	61.4	2026-06-20 18:55:07.225
2627	1	accumulator_temp	61.0	2026-06-20 19:10:07.225
2628	1	accumulator_temp	61.2	2026-06-20 19:25:07.225
2629	1	accumulator_temp	61.3	2026-06-20 19:40:07.225
2630	1	accumulator_temp	62.9	2026-06-20 19:55:07.225
2631	1	accumulator_temp	64.5	2026-06-20 20:10:07.225
2632	1	accumulator_temp	63.9	2026-06-20 20:25:07.225
2633	1	accumulator_temp	63.5	2026-06-20 20:40:07.225
2634	1	accumulator_temp	62.8	2026-06-20 20:55:07.225
2635	1	accumulator_temp	62.9	2026-06-20 21:10:07.225
2636	1	accumulator_temp	65.0	2026-06-20 21:25:07.225
2637	1	accumulator_temp	65.3	2026-06-20 21:40:07.225
2638	1	accumulator_temp	64.4	2026-06-20 21:55:07.225
2639	1	accumulator_temp	66.3	2026-06-20 22:10:07.225
2640	1	accumulator_temp	66.9	2026-06-20 22:25:07.225
2641	1	accumulator_temp	66.0	2026-06-20 22:40:07.225
2642	1	accumulator_temp	65.3	2026-06-20 22:55:07.225
2643	1	accumulator_temp	69.1	2026-06-20 23:10:07.225
2644	1	accumulator_temp	67.6	2026-06-20 23:25:07.225
2645	1	accumulator_temp	67.3	2026-06-20 23:40:07.225
2646	1	accumulator_temp	68.4	2026-06-20 23:55:07.225
2647	1	accumulator_temp	69.7	2026-06-21 00:10:07.225
2648	1	accumulator_temp	71.2	2026-06-21 00:25:07.225
2649	1	accumulator_temp	71.1	2026-06-21 00:40:07.225
2650	1	accumulator_temp	71.1	2026-06-21 00:55:07.225
2651	1	accumulator_temp	71.0	2026-06-21 01:10:07.225
2652	1	accumulator_temp	71.3	2026-06-21 01:25:07.225
2653	1	accumulator_temp	71.3	2026-06-21 01:40:07.225
2654	1	accumulator_temp	70.7	2026-06-21 01:55:07.225
2655	1	accumulator_temp	73.1	2026-06-21 02:10:07.225
2656	1	accumulator_temp	74.1	2026-06-21 02:25:07.225
2657	1	accumulator_temp	73.2	2026-06-21 02:40:07.225
2658	1	accumulator_temp	74.1	2026-06-21 02:55:07.225
2659	1	accumulator_temp	76.4	2026-06-21 03:10:07.225
2660	1	accumulator_temp	75.6	2026-06-21 03:25:07.225
2661	1	accumulator_temp	75.0	2026-06-21 03:40:07.225
2662	1	accumulator_temp	76.3	2026-06-21 03:55:07.225
2663	1	accumulator_temp	78.0	2026-06-21 04:10:07.225
2664	1	accumulator_temp	75.6	2026-06-21 04:25:07.225
2665	1	accumulator_temp	76.1	2026-06-21 04:40:07.225
2666	1	accumulator_temp	77.3	2026-06-21 04:55:07.225
2667	1	accumulator_temp	77.7	2026-06-21 05:10:07.225
2668	1	accumulator_temp	77.9	2026-06-21 05:25:07.225
2669	1	accumulator_temp	77.5	2026-06-21 05:40:07.225
2670	1	accumulator_temp	76.6	2026-06-21 05:55:07.225
2671	1	accumulator_temp	77.7	2026-06-21 06:10:07.225
2672	1	accumulator_temp	77.8	2026-06-21 06:25:07.225
2673	1	accumulator_temp	77.1	2026-06-21 06:40:07.225
2674	1	accumulator_temp	78.2	2026-06-21 06:55:07.225
2675	1	accumulator_temp	76.7	2026-06-21 07:10:07.225
2676	1	accumulator_temp	78.1	2026-06-21 07:25:07.225
2677	1	accumulator_temp	76.4	2026-06-21 07:40:07.225
2678	1	accumulator_temp	77.8	2026-06-21 07:55:07.225
2679	1	accumulator_temp	75.8	2026-06-21 08:10:07.225
2680	1	accumulator_temp	76.9	2026-06-21 08:25:07.225
2681	1	accumulator_temp	76.0	2026-06-21 08:40:07.225
2682	1	accumulator_temp	76.4	2026-06-21 08:55:07.225
2683	1	accumulator_temp	75.9	2026-06-21 09:10:07.225
2684	1	accumulator_temp	74.9	2026-06-21 09:25:07.225
2685	1	accumulator_temp	75.4	2026-06-21 09:40:07.225
2686	1	accumulator_temp	76.1	2026-06-21 09:55:07.225
2687	1	accumulator_temp	73.0	2026-06-21 10:10:07.225
2688	1	accumulator_temp	73.8	2026-06-21 10:25:07.225
2689	1	accumulator_temp	74.3	2026-06-21 10:40:07.225
2690	1	accumulator_temp	74.6	2026-06-21 10:55:07.225
2691	1	accumulator_temp	73.3	2026-06-21 11:10:07.225
2692	1	accumulator_temp	71.0	2026-06-21 11:25:07.225
2693	1	floor_temp	49.9	2026-06-14 11:25:07.225
2694	1	floor_temp	49.0	2026-06-14 11:40:07.225
2695	1	floor_temp	49.7	2026-06-14 11:55:07.225
2696	1	floor_temp	48.6	2026-06-14 12:10:07.225
2697	1	floor_temp	48.6	2026-06-14 12:25:07.225
2698	1	floor_temp	49.0	2026-06-14 12:40:07.225
2699	1	floor_temp	48.5	2026-06-14 12:55:07.225
2700	1	floor_temp	46.5	2026-06-14 13:10:07.225
2701	1	floor_temp	47.6	2026-06-14 13:25:07.225
2702	1	floor_temp	46.8	2026-06-14 13:40:07.225
2703	1	floor_temp	47.5	2026-06-14 13:55:07.225
2704	1	floor_temp	45.7	2026-06-14 14:10:07.225
2705	1	floor_temp	45.9	2026-06-14 14:25:07.225
2706	1	floor_temp	44.7	2026-06-14 14:40:07.225
2707	1	floor_temp	45.8	2026-06-14 14:55:07.225
2708	1	floor_temp	43.8	2026-06-14 15:10:07.225
2709	1	floor_temp	44.0	2026-06-14 15:25:07.225
2710	1	floor_temp	44.9	2026-06-14 15:40:07.225
2711	1	floor_temp	45.3	2026-06-14 15:55:07.225
2712	1	floor_temp	43.3	2026-06-14 16:10:07.225
2713	1	floor_temp	43.7	2026-06-14 16:25:07.225
2714	1	floor_temp	43.9	2026-06-14 16:40:07.225
2715	1	floor_temp	44.5	2026-06-14 16:55:07.225
2716	1	floor_temp	43.1	2026-06-14 17:10:07.225
2717	1	floor_temp	43.3	2026-06-14 17:25:07.225
2718	1	floor_temp	43.6	2026-06-14 17:40:07.225
2719	1	floor_temp	42.2	2026-06-14 17:55:07.225
2720	1	floor_temp	42.6	2026-06-14 18:10:07.225
2721	1	floor_temp	43.3	2026-06-14 18:25:07.225
2722	1	floor_temp	43.0	2026-06-14 18:40:07.225
2723	1	floor_temp	43.4	2026-06-14 18:55:07.225
2724	1	floor_temp	42.9	2026-06-14 19:10:07.225
2725	1	floor_temp	43.3	2026-06-14 19:25:07.225
2726	1	floor_temp	43.1	2026-06-14 19:40:07.225
2727	1	floor_temp	43.2	2026-06-14 19:55:07.225
2728	1	floor_temp	44.1	2026-06-14 20:10:07.225
2729	1	floor_temp	43.2	2026-06-14 20:25:07.225
2730	1	floor_temp	44.6	2026-06-14 20:40:07.225
2731	1	floor_temp	44.6	2026-06-14 20:55:07.225
2732	1	floor_temp	43.6	2026-06-14 21:10:07.225
2733	1	floor_temp	45.2	2026-06-14 21:25:07.225
2734	1	floor_temp	45.4	2026-06-14 21:40:07.225
2735	1	floor_temp	45.1	2026-06-14 21:55:07.225
2736	1	floor_temp	45.9	2026-06-14 22:10:07.225
2737	1	floor_temp	45.9	2026-06-14 22:25:07.225
2738	1	floor_temp	46.5	2026-06-14 22:40:07.225
2739	1	floor_temp	45.3	2026-06-14 22:55:07.225
2740	1	floor_temp	47.1	2026-06-14 23:10:07.225
2741	1	floor_temp	47.7	2026-06-14 23:25:07.225
2742	1	floor_temp	47.3	2026-06-14 23:40:07.225
2743	1	floor_temp	47.5	2026-06-14 23:55:07.225
2744	1	floor_temp	47.8	2026-06-15 00:10:07.225
2745	1	floor_temp	49.0	2026-06-15 00:25:07.225
2746	1	floor_temp	48.9	2026-06-15 00:40:07.225
2747	1	floor_temp	47.1	2026-06-15 00:55:07.225
2748	1	floor_temp	48.9	2026-06-15 01:10:07.225
2749	1	floor_temp	49.9	2026-06-15 01:25:07.225
2750	1	floor_temp	49.9	2026-06-15 01:40:07.225
2751	1	floor_temp	49.6	2026-06-15 01:55:07.225
2752	1	floor_temp	51.0	2026-06-15 02:10:07.225
2753	1	floor_temp	49.7	2026-06-15 02:25:07.225
2754	1	floor_temp	50.5	2026-06-15 02:40:07.225
2755	1	floor_temp	50.0	2026-06-15 02:55:07.225
2756	1	floor_temp	52.0	2026-06-15 03:10:07.225
2757	1	floor_temp	52.5	2026-06-15 03:25:07.225
2758	1	floor_temp	50.6	2026-06-15 03:40:07.225
2759	1	floor_temp	50.9	2026-06-15 03:55:07.225
2760	1	floor_temp	53.0	2026-06-15 04:10:07.225
2761	1	floor_temp	53.1	2026-06-15 04:25:07.225
2762	1	floor_temp	51.9	2026-06-15 04:40:07.225
2763	1	floor_temp	52.3	2026-06-15 04:55:07.225
2764	1	floor_temp	53.6	2026-06-15 05:10:07.225
2765	1	floor_temp	53.4	2026-06-15 05:25:07.225
2766	1	floor_temp	52.1	2026-06-15 05:40:07.225
2767	1	floor_temp	53.4	2026-06-15 05:55:07.225
2768	1	floor_temp	52.4	2026-06-15 06:10:07.225
2769	1	floor_temp	53.9	2026-06-15 06:25:07.225
2770	1	floor_temp	53.6	2026-06-15 06:40:07.225
2771	1	floor_temp	53.9	2026-06-15 06:55:07.225
2772	1	floor_temp	52.5	2026-06-15 07:10:07.225
2773	1	floor_temp	52.4	2026-06-15 07:25:07.225
2774	1	floor_temp	53.4	2026-06-15 07:40:07.225
2775	1	floor_temp	52.5	2026-06-15 07:55:07.225
2776	1	floor_temp	52.4	2026-06-15 08:10:07.225
2777	1	floor_temp	52.7	2026-06-15 08:25:07.225
2778	1	floor_temp	52.6	2026-06-15 08:40:07.225
2779	1	floor_temp	52.4	2026-06-15 08:55:07.225
2780	1	floor_temp	51.4	2026-06-15 09:10:07.225
2781	1	floor_temp	50.9	2026-06-15 09:25:07.225
2782	1	floor_temp	52.1	2026-06-15 09:40:07.225
2783	1	floor_temp	52.0	2026-06-15 09:55:07.225
2784	1	floor_temp	51.5	2026-06-15 10:10:07.225
2785	1	floor_temp	49.6	2026-06-15 10:25:07.225
2786	1	floor_temp	50.8	2026-06-15 10:40:07.225
2787	1	floor_temp	50.3	2026-06-15 10:55:07.225
2788	1	floor_temp	49.8	2026-06-15 11:10:07.225
2789	1	floor_temp	48.8	2026-06-15 11:25:07.225
2790	1	floor_temp	48.7	2026-06-15 11:40:07.225
2791	1	floor_temp	48.7	2026-06-15 11:55:07.225
2792	1	floor_temp	48.5	2026-06-15 12:10:07.225
2793	1	floor_temp	47.8	2026-06-15 12:25:07.225
2794	1	floor_temp	48.0	2026-06-15 12:40:07.225
2795	1	floor_temp	47.0	2026-06-15 12:55:07.225
2796	1	floor_temp	46.9	2026-06-15 13:10:07.225
2797	1	floor_temp	46.3	2026-06-15 13:25:07.225
2798	1	floor_temp	47.1	2026-06-15 13:40:07.225
2799	1	floor_temp	46.7	2026-06-15 13:55:07.225
2800	1	floor_temp	46.1	2026-06-15 14:10:07.225
2801	1	floor_temp	45.0	2026-06-15 14:25:07.225
2802	1	floor_temp	45.6	2026-06-15 14:40:07.225
2803	1	floor_temp	44.6	2026-06-15 14:55:07.225
2804	1	floor_temp	43.5	2026-06-15 15:10:07.225
2805	1	floor_temp	44.8	2026-06-15 15:25:07.225
2806	1	floor_temp	44.1	2026-06-15 15:40:07.225
2807	1	floor_temp	43.6	2026-06-15 15:55:07.225
2808	1	floor_temp	43.0	2026-06-15 16:10:07.225
2809	1	floor_temp	43.5	2026-06-15 16:25:07.225
2810	1	floor_temp	43.7	2026-06-15 16:40:07.225
2811	1	floor_temp	44.2	2026-06-15 16:55:07.225
2812	1	floor_temp	42.5	2026-06-15 17:10:07.225
2813	1	floor_temp	42.5	2026-06-15 17:25:07.225
2814	1	floor_temp	43.9	2026-06-15 17:40:07.225
2815	1	floor_temp	44.0	2026-06-15 17:55:07.225
2816	1	floor_temp	43.1	2026-06-15 18:10:07.225
2817	1	floor_temp	42.1	2026-06-15 18:25:07.225
2818	1	floor_temp	43.6	2026-06-15 18:40:07.225
2819	1	floor_temp	43.5	2026-06-15 18:55:07.225
2820	1	floor_temp	42.7	2026-06-15 19:10:07.225
2821	1	floor_temp	43.5	2026-06-15 19:25:07.225
2822	1	floor_temp	43.8	2026-06-15 19:40:07.225
2823	1	floor_temp	42.9	2026-06-15 19:55:07.225
2824	1	floor_temp	43.4	2026-06-15 20:10:07.225
2825	1	floor_temp	42.8	2026-06-15 20:25:07.225
2826	1	floor_temp	44.3	2026-06-15 20:40:07.225
2827	1	floor_temp	42.9	2026-06-15 20:55:07.225
2828	1	floor_temp	45.0	2026-06-15 21:10:07.225
2829	1	floor_temp	44.8	2026-06-15 21:25:07.225
2830	1	floor_temp	45.4	2026-06-15 21:40:07.225
2831	1	floor_temp	44.4	2026-06-15 21:55:07.225
2832	1	floor_temp	45.9	2026-06-15 22:10:07.225
2833	1	floor_temp	46.0	2026-06-15 22:25:07.225
2834	1	floor_temp	46.2	2026-06-15 22:40:07.225
2835	1	floor_temp	45.8	2026-06-15 22:55:07.225
2836	1	floor_temp	47.5	2026-06-15 23:10:07.225
2837	1	floor_temp	46.0	2026-06-15 23:25:07.225
2838	1	floor_temp	46.7	2026-06-15 23:40:07.225
2839	1	floor_temp	46.1	2026-06-15 23:55:07.225
2840	1	floor_temp	48.4	2026-06-16 00:10:07.225
2841	1	floor_temp	48.1	2026-06-16 00:25:07.225
2842	1	floor_temp	47.4	2026-06-16 00:40:07.225
2843	1	floor_temp	47.3	2026-06-16 00:55:07.225
2844	1	floor_temp	48.7	2026-06-16 01:10:07.225
2845	1	floor_temp	49.2	2026-06-16 01:25:07.225
2846	1	floor_temp	49.5	2026-06-16 01:40:07.225
2847	1	floor_temp	50.2	2026-06-16 01:55:07.225
2848	1	floor_temp	49.8	2026-06-16 02:10:07.225
2849	1	floor_temp	51.3	2026-06-16 02:25:07.225
2850	1	floor_temp	50.6	2026-06-16 02:40:07.225
2851	1	floor_temp	51.2	2026-06-16 02:55:07.225
2852	1	floor_temp	52.3	2026-06-16 03:10:07.225
2853	1	floor_temp	51.7	2026-06-16 03:25:07.225
2854	1	floor_temp	51.6	2026-06-16 03:40:07.225
2855	1	floor_temp	52.2	2026-06-16 03:55:07.225
2856	1	floor_temp	51.7	2026-06-16 04:10:07.225
2857	1	floor_temp	53.3	2026-06-16 04:25:07.225
2858	1	floor_temp	51.5	2026-06-16 04:40:07.225
2859	1	floor_temp	52.6	2026-06-16 04:55:07.225
2860	1	floor_temp	52.4	2026-06-16 05:10:07.225
2861	1	floor_temp	53.5	2026-06-16 05:25:07.225
2862	1	floor_temp	53.6	2026-06-16 05:40:07.225
2863	1	floor_temp	53.3	2026-06-16 05:55:07.225
2864	1	floor_temp	52.7	2026-06-16 06:10:07.225
2865	1	floor_temp	52.6	2026-06-16 06:25:07.225
2866	1	floor_temp	53.1	2026-06-16 06:40:07.225
2867	1	floor_temp	53.9	2026-06-16 06:55:07.225
2868	1	floor_temp	52.6	2026-06-16 07:10:07.225
2869	1	floor_temp	52.6	2026-06-16 07:25:07.225
2870	1	floor_temp	52.0	2026-06-16 07:40:07.225
2871	1	floor_temp	52.9	2026-06-16 07:55:07.225
2872	1	floor_temp	52.8	2026-06-16 08:10:07.225
2873	1	floor_temp	53.3	2026-06-16 08:25:07.225
2874	1	floor_temp	52.8	2026-06-16 08:40:07.225
2875	1	floor_temp	53.0	2026-06-16 08:55:07.225
2876	1	floor_temp	51.4	2026-06-16 09:10:07.225
2877	1	floor_temp	52.0	2026-06-16 09:25:07.225
2878	1	floor_temp	51.5	2026-06-16 09:40:07.225
2879	1	floor_temp	50.6	2026-06-16 09:55:07.225
2880	1	floor_temp	49.8	2026-06-16 10:10:07.225
2881	1	floor_temp	50.0	2026-06-16 10:25:07.225
2882	1	floor_temp	49.9	2026-06-16 10:40:07.225
2883	1	floor_temp	50.5	2026-06-16 10:55:07.225
2884	1	floor_temp	49.2	2026-06-16 11:10:07.225
2885	1	floor_temp	49.3	2026-06-16 11:25:07.225
2886	1	floor_temp	48.4	2026-06-16 11:40:07.225
2887	1	floor_temp	50.2	2026-06-16 11:55:07.225
2888	1	floor_temp	47.2	2026-06-16 12:10:07.225
2889	1	floor_temp	48.2	2026-06-16 12:25:07.225
2890	1	floor_temp	47.4	2026-06-16 12:40:07.225
2891	1	floor_temp	48.2	2026-06-16 12:55:07.225
2892	1	floor_temp	47.0	2026-06-16 13:10:07.225
2893	1	floor_temp	47.3	2026-06-16 13:25:07.225
2894	1	floor_temp	46.7	2026-06-16 13:40:07.225
2895	1	floor_temp	46.7	2026-06-16 13:55:07.225
2896	1	floor_temp	45.4	2026-06-16 14:10:07.225
2897	1	floor_temp	45.3	2026-06-16 14:25:07.225
2898	1	floor_temp	45.5	2026-06-16 14:40:07.225
2899	1	floor_temp	44.7	2026-06-16 14:55:07.225
2900	1	floor_temp	44.0	2026-06-16 15:10:07.225
2901	1	floor_temp	44.1	2026-06-16 15:25:07.225
2902	1	floor_temp	44.0	2026-06-16 15:40:07.225
2903	1	floor_temp	43.7	2026-06-16 15:55:07.225
2904	1	floor_temp	42.7	2026-06-16 16:10:07.225
2905	1	floor_temp	43.4	2026-06-16 16:25:07.225
2906	1	floor_temp	43.3	2026-06-16 16:40:07.225
2907	1	floor_temp	43.3	2026-06-16 16:55:07.225
2908	1	floor_temp	42.2	2026-06-16 17:10:07.225
2909	1	floor_temp	43.1	2026-06-16 17:25:07.225
2910	1	floor_temp	42.4	2026-06-16 17:40:07.225
2911	1	floor_temp	43.1	2026-06-16 17:55:07.225
2912	1	floor_temp	42.1	2026-06-16 18:10:07.225
2913	1	floor_temp	43.5	2026-06-16 18:25:07.225
2914	1	floor_temp	43.9	2026-06-16 18:40:07.225
2915	1	floor_temp	43.1	2026-06-16 18:55:07.225
2916	1	floor_temp	43.3	2026-06-16 19:10:07.225
2917	1	floor_temp	42.9	2026-06-16 19:25:07.225
2918	1	floor_temp	43.1	2026-06-16 19:40:07.225
2919	1	floor_temp	43.1	2026-06-16 19:55:07.225
2920	1	floor_temp	43.8	2026-06-16 20:10:07.225
2921	1	floor_temp	44.6	2026-06-16 20:25:07.225
2922	1	floor_temp	44.2	2026-06-16 20:40:07.225
2923	1	floor_temp	44.0	2026-06-16 20:55:07.225
2924	1	floor_temp	44.8	2026-06-16 21:10:07.225
2925	1	floor_temp	44.7	2026-06-16 21:25:07.225
2926	1	floor_temp	45.1	2026-06-16 21:40:07.225
2927	1	floor_temp	44.9	2026-06-16 21:55:07.225
2928	1	floor_temp	46.2	2026-06-16 22:10:07.225
2929	1	floor_temp	46.3	2026-06-16 22:25:07.225
2930	1	floor_temp	45.6	2026-06-16 22:40:07.225
2931	1	floor_temp	46.3	2026-06-16 22:55:07.225
2932	1	floor_temp	46.7	2026-06-16 23:10:07.225
2933	1	floor_temp	47.1	2026-06-16 23:25:07.225
2934	1	floor_temp	47.1	2026-06-16 23:40:07.225
2935	1	floor_temp	46.8	2026-06-16 23:55:07.225
2936	1	floor_temp	48.5	2026-06-17 00:10:07.225
2937	1	floor_temp	47.4	2026-06-17 00:25:07.225
2938	1	floor_temp	48.1	2026-06-17 00:40:07.225
2939	1	floor_temp	48.3	2026-06-17 00:55:07.225
2940	1	floor_temp	48.3	2026-06-17 01:10:07.225
2941	1	floor_temp	48.6	2026-06-17 01:25:07.225
2942	1	floor_temp	49.4	2026-06-17 01:40:07.225
2943	1	floor_temp	49.2	2026-06-17 01:55:07.225
2944	1	floor_temp	50.3	2026-06-17 02:10:07.225
2945	1	floor_temp	50.3	2026-06-17 02:25:07.225
2946	1	floor_temp	49.8	2026-06-17 02:40:07.225
2947	1	floor_temp	49.9	2026-06-17 02:55:07.225
2948	1	floor_temp	50.9	2026-06-17 03:10:07.225
2949	1	floor_temp	51.5	2026-06-17 03:25:07.225
2950	1	floor_temp	50.7	2026-06-17 03:40:07.225
2951	1	floor_temp	51.3	2026-06-17 03:55:07.225
2952	1	floor_temp	51.9	2026-06-17 04:10:07.225
2953	1	floor_temp	53.2	2026-06-17 04:25:07.225
2954	1	floor_temp	51.5	2026-06-17 04:40:07.225
2955	1	floor_temp	51.9	2026-06-17 04:55:07.225
2956	1	floor_temp	53.2	2026-06-17 05:10:07.225
2957	1	floor_temp	51.8	2026-06-17 05:25:07.225
2958	1	floor_temp	51.9	2026-06-17 05:40:07.225
2959	1	floor_temp	52.3	2026-06-17 05:55:07.225
2960	1	floor_temp	52.3	2026-06-17 06:10:07.225
2961	1	floor_temp	53.8	2026-06-17 06:25:07.225
2962	1	floor_temp	52.5	2026-06-17 06:40:07.225
2963	1	floor_temp	53.2	2026-06-17 06:55:07.225
2964	1	floor_temp	52.7	2026-06-17 07:10:07.225
2965	1	floor_temp	53.6	2026-06-17 07:25:07.225
2966	1	floor_temp	53.4	2026-06-17 07:40:07.225
2967	1	floor_temp	52.0	2026-06-17 07:55:07.225
2968	1	floor_temp	52.5	2026-06-17 08:10:07.225
2969	1	floor_temp	52.6	2026-06-17 08:25:07.225
2970	1	floor_temp	52.4	2026-06-17 08:40:07.225
2971	1	floor_temp	52.7	2026-06-17 08:55:07.225
2972	1	floor_temp	51.9	2026-06-17 09:10:07.225
2973	1	floor_temp	51.5	2026-06-17 09:25:07.225
2974	1	floor_temp	52.1	2026-06-17 09:40:07.225
2975	1	floor_temp	52.2	2026-06-17 09:55:07.225
2976	1	floor_temp	49.6	2026-06-17 10:10:07.225
2977	1	floor_temp	50.5	2026-06-17 10:25:07.225
2978	1	floor_temp	50.0	2026-06-17 10:40:07.225
2979	1	floor_temp	50.6	2026-06-17 10:55:07.225
2980	1	floor_temp	49.7	2026-06-17 11:10:07.225
2981	1	floor_temp	48.3	2026-06-17 11:25:07.225
2982	1	floor_temp	49.0	2026-06-17 11:40:07.225
2983	1	floor_temp	49.3	2026-06-17 11:55:07.225
2984	1	floor_temp	47.4	2026-06-17 12:10:07.225
2985	1	floor_temp	47.5	2026-06-17 12:25:07.225
2986	1	floor_temp	47.6	2026-06-17 12:40:07.225
2987	1	floor_temp	48.4	2026-06-17 12:55:07.225
2988	1	floor_temp	46.3	2026-06-17 13:10:07.225
2989	1	floor_temp	47.0	2026-06-17 13:25:07.225
2990	1	floor_temp	46.9	2026-06-17 13:40:07.225
2991	1	floor_temp	46.1	2026-06-17 13:55:07.225
2992	1	floor_temp	45.6	2026-06-17 14:10:07.225
2993	1	floor_temp	46.0	2026-06-17 14:25:07.225
2994	1	floor_temp	44.7	2026-06-17 14:40:07.225
2995	1	floor_temp	45.6	2026-06-17 14:55:07.225
2996	1	floor_temp	45.1	2026-06-17 15:10:07.225
2997	1	floor_temp	44.8	2026-06-17 15:25:07.225
2998	1	floor_temp	44.2	2026-06-17 15:40:07.225
2999	1	floor_temp	44.3	2026-06-17 15:55:07.225
3000	1	floor_temp	42.7	2026-06-17 16:10:07.225
3001	1	floor_temp	44.3	2026-06-17 16:25:07.225
3002	1	floor_temp	44.2	2026-06-17 16:40:07.225
3003	1	floor_temp	43.1	2026-06-17 16:55:07.225
3004	1	floor_temp	42.8	2026-06-17 17:10:07.225
3005	1	floor_temp	43.7	2026-06-17 17:25:07.225
3006	1	floor_temp	43.3	2026-06-17 17:40:07.225
3007	1	floor_temp	43.9	2026-06-17 17:55:07.225
3008	1	floor_temp	42.4	2026-06-17 18:10:07.225
3009	1	floor_temp	42.4	2026-06-17 18:25:07.225
3010	1	floor_temp	42.7	2026-06-17 18:40:07.225
3011	1	floor_temp	42.1	2026-06-17 18:55:07.225
3012	1	floor_temp	43.2	2026-06-17 19:10:07.225
3013	1	floor_temp	43.6	2026-06-17 19:25:07.225
3014	1	floor_temp	43.9	2026-06-17 19:40:07.225
3015	1	floor_temp	43.1	2026-06-17 19:55:07.225
3016	1	floor_temp	44.5	2026-06-17 20:10:07.225
3017	1	floor_temp	42.8	2026-06-17 20:25:07.225
3018	1	floor_temp	44.2	2026-06-17 20:40:07.225
3019	1	floor_temp	44.5	2026-06-17 20:55:07.225
3020	1	floor_temp	43.6	2026-06-17 21:10:07.225
3021	1	floor_temp	43.8	2026-06-17 21:25:07.225
3022	1	floor_temp	43.9	2026-06-17 21:40:07.225
3023	1	floor_temp	43.7	2026-06-17 21:55:07.225
3024	1	floor_temp	46.3	2026-06-17 22:10:07.225
3025	1	floor_temp	45.2	2026-06-17 22:25:07.225
3026	1	floor_temp	44.8	2026-06-17 22:40:07.225
3027	1	floor_temp	45.0	2026-06-17 22:55:07.225
3028	1	floor_temp	47.4	2026-06-17 23:10:07.225
3029	1	floor_temp	46.5	2026-06-17 23:25:07.225
3030	1	floor_temp	46.3	2026-06-17 23:40:07.225
3031	1	floor_temp	47.3	2026-06-17 23:55:07.225
3032	1	floor_temp	48.1	2026-06-18 00:10:07.225
3033	1	floor_temp	47.7	2026-06-18 00:25:07.225
3034	1	floor_temp	48.8	2026-06-18 00:40:07.225
3035	1	floor_temp	48.7	2026-06-18 00:55:07.225
3036	1	floor_temp	49.3	2026-06-18 01:10:07.225
3037	1	floor_temp	48.7	2026-06-18 01:25:07.225
3038	1	floor_temp	50.3	2026-06-18 01:40:07.225
3039	1	floor_temp	49.4	2026-06-18 01:55:07.225
3040	1	floor_temp	51.3	2026-06-18 02:10:07.225
3041	1	floor_temp	51.4	2026-06-18 02:25:07.225
3042	1	floor_temp	51.2	2026-06-18 02:40:07.225
3043	1	floor_temp	50.8	2026-06-18 02:55:07.225
3044	1	floor_temp	51.9	2026-06-18 03:10:07.225
3045	1	floor_temp	50.7	2026-06-18 03:25:07.225
3046	1	floor_temp	52.3	2026-06-18 03:40:07.225
3047	1	floor_temp	50.9	2026-06-18 03:55:07.225
3048	1	floor_temp	52.2	2026-06-18 04:10:07.225
3049	1	floor_temp	52.2	2026-06-18 04:25:07.225
3050	1	floor_temp	52.5	2026-06-18 04:40:07.225
3051	1	floor_temp	52.9	2026-06-18 04:55:07.225
3052	1	floor_temp	53.3	2026-06-18 05:10:07.225
3053	1	floor_temp	53.4	2026-06-18 05:25:07.225
3054	1	floor_temp	53.8	2026-06-18 05:40:07.225
3055	1	floor_temp	53.1	2026-06-18 05:55:07.225
3056	1	floor_temp	53.1	2026-06-18 06:10:07.225
3057	1	floor_temp	52.9	2026-06-18 06:25:07.225
3058	1	floor_temp	52.5	2026-06-18 06:40:07.225
3059	1	floor_temp	52.0	2026-06-18 06:55:07.225
3060	1	floor_temp	52.5	2026-06-18 07:10:07.225
3061	1	floor_temp	52.9	2026-06-18 07:25:07.225
3062	1	floor_temp	52.0	2026-06-18 07:40:07.225
3063	1	floor_temp	52.9	2026-06-18 07:55:07.225
3064	1	floor_temp	51.4	2026-06-18 08:10:07.225
3065	1	floor_temp	52.7	2026-06-18 08:25:07.225
3066	1	floor_temp	53.3	2026-06-18 08:40:07.225
3067	1	floor_temp	51.7	2026-06-18 08:55:07.225
3068	1	floor_temp	50.6	2026-06-18 09:10:07.225
3069	1	floor_temp	52.1	2026-06-18 09:25:07.225
3070	1	floor_temp	51.1	2026-06-18 09:40:07.225
3071	1	floor_temp	51.6	2026-06-18 09:55:07.225
3072	1	floor_temp	50.3	2026-06-18 10:10:07.225
3073	1	floor_temp	51.0	2026-06-18 10:25:07.225
3074	1	floor_temp	51.2	2026-06-18 10:40:07.225
3075	1	floor_temp	51.0	2026-06-18 10:55:07.225
3076	1	floor_temp	49.2	2026-06-18 11:10:07.225
3077	1	floor_temp	49.5	2026-06-18 11:25:07.225
3078	1	floor_temp	49.5	2026-06-18 11:40:07.225
3079	1	floor_temp	48.4	2026-06-18 11:55:07.225
3080	1	floor_temp	48.2	2026-06-18 12:10:07.225
3081	1	floor_temp	48.0	2026-06-18 12:25:07.225
3082	1	floor_temp	47.1	2026-06-18 12:40:07.225
3083	1	floor_temp	47.4	2026-06-18 12:55:07.225
3084	1	floor_temp	46.9	2026-06-18 13:10:07.225
3085	1	floor_temp	46.4	2026-06-18 13:25:07.225
3086	1	floor_temp	46.7	2026-06-18 13:40:07.225
3087	1	floor_temp	46.6	2026-06-18 13:55:07.225
3088	1	floor_temp	45.1	2026-06-18 14:10:07.225
3089	1	floor_temp	46.1	2026-06-18 14:25:07.225
3090	1	floor_temp	45.8	2026-06-18 14:40:07.225
3091	1	floor_temp	44.7	2026-06-18 14:55:07.225
3092	1	floor_temp	45.2	2026-06-18 15:10:07.225
3093	1	floor_temp	44.7	2026-06-18 15:25:07.225
3094	1	floor_temp	44.4	2026-06-18 15:40:07.225
3095	1	floor_temp	43.5	2026-06-18 15:55:07.225
3096	1	floor_temp	43.5	2026-06-18 16:10:07.225
3097	1	floor_temp	43.9	2026-06-18 16:25:07.225
3098	1	floor_temp	44.6	2026-06-18 16:40:07.225
3099	1	floor_temp	44.5	2026-06-18 16:55:07.225
3100	1	floor_temp	43.8	2026-06-18 17:10:07.225
3101	1	floor_temp	42.5	2026-06-18 17:25:07.225
3102	1	floor_temp	43.4	2026-06-18 17:40:07.225
3103	1	floor_temp	43.1	2026-06-18 17:55:07.225
3104	1	floor_temp	43.5	2026-06-18 18:10:07.225
3105	1	floor_temp	42.8	2026-06-18 18:25:07.225
3106	1	floor_temp	43.1	2026-06-18 18:40:07.225
3107	1	floor_temp	43.1	2026-06-18 18:55:07.225
3108	1	floor_temp	42.6	2026-06-18 19:10:07.225
3109	1	floor_temp	42.6	2026-06-18 19:25:07.225
3110	1	floor_temp	42.9	2026-06-18 19:40:07.225
3111	1	floor_temp	42.7	2026-06-18 19:55:07.225
3112	1	floor_temp	44.0	2026-06-18 20:10:07.225
3113	1	floor_temp	44.1	2026-06-18 20:25:07.225
3114	1	floor_temp	43.7	2026-06-18 20:40:07.225
3115	1	floor_temp	44.2	2026-06-18 20:55:07.225
3116	1	floor_temp	45.0	2026-06-18 21:10:07.225
3117	1	floor_temp	45.3	2026-06-18 21:25:07.225
3118	1	floor_temp	45.3	2026-06-18 21:40:07.225
3119	1	floor_temp	45.0	2026-06-18 21:55:07.225
3120	1	floor_temp	44.9	2026-06-18 22:10:07.225
3121	1	floor_temp	45.8	2026-06-18 22:25:07.225
3122	1	floor_temp	45.3	2026-06-18 22:40:07.225
3123	1	floor_temp	45.4	2026-06-18 22:55:07.225
3124	1	floor_temp	47.3	2026-06-18 23:10:07.225
3125	1	floor_temp	45.8	2026-06-18 23:25:07.225
3126	1	floor_temp	46.0	2026-06-18 23:40:07.225
3127	1	floor_temp	47.2	2026-06-18 23:55:07.225
3128	1	floor_temp	48.9	2026-06-19 00:10:07.225
3129	1	floor_temp	47.2	2026-06-19 00:25:07.225
3130	1	floor_temp	49.0	2026-06-19 00:40:07.225
3131	1	floor_temp	47.5	2026-06-19 00:55:07.225
3132	1	floor_temp	49.3	2026-06-19 01:10:07.225
3133	1	floor_temp	48.5	2026-06-19 01:25:07.225
3134	1	floor_temp	48.7	2026-06-19 01:40:07.225
3135	1	floor_temp	49.1	2026-06-19 01:55:07.225
3136	1	floor_temp	49.8	2026-06-19 02:10:07.225
3137	1	floor_temp	49.9	2026-06-19 02:25:07.225
3138	1	floor_temp	51.1	2026-06-19 02:40:07.225
3139	1	floor_temp	50.9	2026-06-19 02:55:07.225
3140	1	floor_temp	52.4	2026-06-19 03:10:07.225
3141	1	floor_temp	51.1	2026-06-19 03:25:07.225
3142	1	floor_temp	52.3	2026-06-19 03:40:07.225
3143	1	floor_temp	50.8	2026-06-19 03:55:07.225
3144	1	floor_temp	52.6	2026-06-19 04:10:07.225
3145	1	floor_temp	52.0	2026-06-19 04:25:07.225
3146	1	floor_temp	52.1	2026-06-19 04:40:07.225
3147	1	floor_temp	51.4	2026-06-19 04:55:07.225
3148	1	floor_temp	52.2	2026-06-19 05:10:07.225
3149	1	floor_temp	52.9	2026-06-19 05:25:07.225
3150	1	floor_temp	53.6	2026-06-19 05:40:07.225
3151	1	floor_temp	52.0	2026-06-19 05:55:07.225
3152	1	floor_temp	52.2	2026-06-19 06:10:07.225
3153	1	floor_temp	53.9	2026-06-19 06:25:07.225
3154	1	floor_temp	52.6	2026-06-19 06:40:07.225
3155	1	floor_temp	53.8	2026-06-19 06:55:07.225
3156	1	floor_temp	52.0	2026-06-19 07:10:07.225
3157	1	floor_temp	53.3	2026-06-19 07:25:07.225
3158	1	floor_temp	53.4	2026-06-19 07:40:07.225
3159	1	floor_temp	52.0	2026-06-19 07:55:07.225
3160	1	floor_temp	52.7	2026-06-19 08:10:07.225
3161	1	floor_temp	53.3	2026-06-19 08:25:07.225
3162	1	floor_temp	52.0	2026-06-19 08:40:07.225
3163	1	floor_temp	53.2	2026-06-19 08:55:07.225
3164	1	floor_temp	51.3	2026-06-19 09:10:07.225
3165	1	floor_temp	51.9	2026-06-19 09:25:07.225
3166	1	floor_temp	51.7	2026-06-19 09:40:07.225
3167	1	floor_temp	51.5	2026-06-19 09:55:07.225
3168	1	floor_temp	50.8	2026-06-19 10:10:07.225
3169	1	floor_temp	50.3	2026-06-19 10:25:07.225
3170	1	floor_temp	51.1	2026-06-19 10:40:07.225
3171	1	floor_temp	49.9	2026-06-19 10:55:07.225
3172	1	floor_temp	49.3	2026-06-19 11:10:07.225
3173	1	floor_temp	50.2	2026-06-19 11:25:07.225
3174	1	floor_temp	49.7	2026-06-19 11:40:07.225
3175	1	floor_temp	49.4	2026-06-19 11:55:07.225
3176	1	floor_temp	47.9	2026-06-19 12:10:07.225
3177	1	floor_temp	48.0	2026-06-19 12:25:07.225
3178	1	floor_temp	48.0	2026-06-19 12:40:07.225
3179	1	floor_temp	47.3	2026-06-19 12:55:07.225
3180	1	floor_temp	47.7	2026-06-19 13:10:07.225
3181	1	floor_temp	47.3	2026-06-19 13:25:07.225
3182	1	floor_temp	47.3	2026-06-19 13:40:07.225
3183	1	floor_temp	45.7	2026-06-19 13:55:07.225
3184	1	floor_temp	45.0	2026-06-19 14:10:07.225
3185	1	floor_temp	45.7	2026-06-19 14:25:07.225
3186	1	floor_temp	44.6	2026-06-19 14:40:07.225
3187	1	floor_temp	44.5	2026-06-19 14:55:07.225
3188	1	floor_temp	44.6	2026-06-19 15:10:07.225
3189	1	floor_temp	44.4	2026-06-19 15:25:07.225
3190	1	floor_temp	44.9	2026-06-19 15:40:07.225
3191	1	floor_temp	45.0	2026-06-19 15:55:07.225
3192	1	floor_temp	43.2	2026-06-19 16:10:07.225
3193	1	floor_temp	43.4	2026-06-19 16:25:07.225
3194	1	floor_temp	43.0	2026-06-19 16:40:07.225
3195	1	floor_temp	43.4	2026-06-19 16:55:07.225
3196	1	floor_temp	43.4	2026-06-19 17:10:07.225
3197	1	floor_temp	43.1	2026-06-19 17:25:07.225
3198	1	floor_temp	43.6	2026-06-19 17:40:07.225
3199	1	floor_temp	43.7	2026-06-19 17:55:07.225
3200	1	floor_temp	42.1	2026-06-19 18:10:07.225
3201	1	floor_temp	42.9	2026-06-19 18:25:07.225
3202	1	floor_temp	42.8	2026-06-19 18:40:07.225
3203	1	floor_temp	43.3	2026-06-19 18:55:07.225
3204	1	floor_temp	43.9	2026-06-19 19:10:07.225
3205	1	floor_temp	42.6	2026-06-19 19:25:07.225
3206	1	floor_temp	43.6	2026-06-19 19:40:07.225
3207	1	floor_temp	43.8	2026-06-19 19:55:07.225
3208	1	floor_temp	43.6	2026-06-19 20:10:07.225
3209	1	floor_temp	44.3	2026-06-19 20:25:07.225
3210	1	floor_temp	43.3	2026-06-19 20:40:07.225
3211	1	floor_temp	42.7	2026-06-19 20:55:07.225
3212	1	floor_temp	44.3	2026-06-19 21:10:07.225
3213	1	floor_temp	44.8	2026-06-19 21:25:07.225
3214	1	floor_temp	43.9	2026-06-19 21:40:07.225
3215	1	floor_temp	43.6	2026-06-19 21:55:07.225
3216	1	floor_temp	46.4	2026-06-19 22:10:07.225
3217	1	floor_temp	45.8	2026-06-19 22:25:07.225
3218	1	floor_temp	44.9	2026-06-19 22:40:07.225
3219	1	floor_temp	46.0	2026-06-19 22:55:07.225
3220	1	floor_temp	46.6	2026-06-19 23:10:07.225
3221	1	floor_temp	46.4	2026-06-19 23:25:07.225
3222	1	floor_temp	47.7	2026-06-19 23:40:07.225
3223	1	floor_temp	46.5	2026-06-19 23:55:07.225
3224	1	floor_temp	47.5	2026-06-20 00:10:07.225
3225	1	floor_temp	47.2	2026-06-20 00:25:07.225
3226	1	floor_temp	48.0	2026-06-20 00:40:07.225
3227	1	floor_temp	47.2	2026-06-20 00:55:07.225
3228	1	floor_temp	50.0	2026-06-20 01:10:07.225
3229	1	floor_temp	48.6	2026-06-20 01:25:07.225
3230	1	floor_temp	48.8	2026-06-20 01:40:07.225
3231	1	floor_temp	49.7	2026-06-20 01:55:07.225
3232	1	floor_temp	49.7	2026-06-20 02:10:07.225
3233	1	floor_temp	50.5	2026-06-20 02:25:07.225
3234	1	floor_temp	50.5	2026-06-20 02:40:07.225
3235	1	floor_temp	50.1	2026-06-20 02:55:07.225
3236	1	floor_temp	51.3	2026-06-20 03:10:07.225
3237	1	floor_temp	52.3	2026-06-20 03:25:07.225
3238	1	floor_temp	51.0	2026-06-20 03:40:07.225
3239	1	floor_temp	50.8	2026-06-20 03:55:07.225
3240	1	floor_temp	53.2	2026-06-20 04:10:07.225
3241	1	floor_temp	51.5	2026-06-20 04:25:07.225
3242	1	floor_temp	52.8	2026-06-20 04:40:07.225
3243	1	floor_temp	51.9	2026-06-20 04:55:07.225
3244	1	floor_temp	53.6	2026-06-20 05:10:07.225
3245	1	floor_temp	53.5	2026-06-20 05:25:07.225
3246	1	floor_temp	53.4	2026-06-20 05:40:07.225
3247	1	floor_temp	52.7	2026-06-20 05:55:07.225
3248	1	floor_temp	52.4	2026-06-20 06:10:07.225
3249	1	floor_temp	52.2	2026-06-20 06:25:07.225
3250	1	floor_temp	52.2	2026-06-20 06:40:07.225
3251	1	floor_temp	53.0	2026-06-20 06:55:07.225
3252	1	floor_temp	53.2	2026-06-20 07:10:07.225
3253	1	floor_temp	52.5	2026-06-20 07:25:07.225
3254	1	floor_temp	52.5	2026-06-20 07:40:07.225
3255	1	floor_temp	52.6	2026-06-20 07:55:07.225
3256	1	floor_temp	53.0	2026-06-20 08:10:07.225
3257	1	floor_temp	53.0	2026-06-20 08:25:07.225
3258	1	floor_temp	53.2	2026-06-20 08:40:07.225
3259	1	floor_temp	53.1	2026-06-20 08:55:07.225
3260	1	floor_temp	51.7	2026-06-20 09:10:07.225
3261	1	floor_temp	51.3	2026-06-20 09:25:07.225
3262	1	floor_temp	52.1	2026-06-20 09:40:07.225
3263	1	floor_temp	52.3	2026-06-20 09:55:07.225
3264	1	floor_temp	51.0	2026-06-20 10:10:07.225
3265	1	floor_temp	49.6	2026-06-20 10:25:07.225
3266	1	floor_temp	49.6	2026-06-20 10:40:07.225
3267	1	floor_temp	51.3	2026-06-20 10:55:07.225
3268	1	floor_temp	50.0	2026-06-20 11:10:07.225
3269	1	floor_temp	49.5	2026-06-20 11:25:07.225
3270	1	floor_temp	48.3	2026-06-20 11:40:07.225
3271	1	floor_temp	49.2	2026-06-20 11:55:07.225
3272	1	floor_temp	48.9	2026-06-20 12:10:07.225
3273	1	floor_temp	47.9	2026-06-20 12:25:07.225
3274	1	floor_temp	47.3	2026-06-20 12:40:07.225
3275	1	floor_temp	48.6	2026-06-20 12:55:07.225
3276	1	floor_temp	46.8	2026-06-20 13:10:07.225
3277	1	floor_temp	47.6	2026-06-20 13:25:07.225
3278	1	floor_temp	47.5	2026-06-20 13:40:07.225
3279	1	floor_temp	46.6	2026-06-20 13:55:07.225
3280	1	floor_temp	44.6	2026-06-20 14:10:07.225
3281	1	floor_temp	44.6	2026-06-20 14:25:07.225
3282	1	floor_temp	45.9	2026-06-20 14:40:07.225
3283	1	floor_temp	45.6	2026-06-20 14:55:07.225
3284	1	floor_temp	45.1	2026-06-20 15:10:07.225
3285	1	floor_temp	45.1	2026-06-20 15:25:07.225
3286	1	floor_temp	44.4	2026-06-20 15:40:07.225
3287	1	floor_temp	43.7	2026-06-20 15:55:07.225
3288	1	floor_temp	42.7	2026-06-20 16:10:07.225
3289	1	floor_temp	43.7	2026-06-20 16:25:07.225
3290	1	floor_temp	44.5	2026-06-20 16:40:07.225
3291	1	floor_temp	44.5	2026-06-20 16:55:07.225
3292	1	floor_temp	42.7	2026-06-20 17:10:07.225
3293	1	floor_temp	44.1	2026-06-20 17:25:07.225
3294	1	floor_temp	43.7	2026-06-20 17:40:07.225
3295	1	floor_temp	43.6	2026-06-20 17:55:07.225
3296	1	floor_temp	42.7	2026-06-20 18:10:07.225
3297	1	floor_temp	42.1	2026-06-20 18:25:07.225
3298	1	floor_temp	43.5	2026-06-20 18:40:07.225
3299	1	floor_temp	42.3	2026-06-20 18:55:07.225
3300	1	floor_temp	44.1	2026-06-20 19:10:07.225
3301	1	floor_temp	43.5	2026-06-20 19:25:07.225
3302	1	floor_temp	42.7	2026-06-20 19:40:07.225
3303	1	floor_temp	42.3	2026-06-20 19:55:07.225
3304	1	floor_temp	44.4	2026-06-20 20:10:07.225
3305	1	floor_temp	43.2	2026-06-20 20:25:07.225
3306	1	floor_temp	43.2	2026-06-20 20:40:07.225
3307	1	floor_temp	42.7	2026-06-20 20:55:07.225
3308	1	floor_temp	45.3	2026-06-20 21:10:07.225
3309	1	floor_temp	43.6	2026-06-20 21:25:07.225
3310	1	floor_temp	43.9	2026-06-20 21:40:07.225
3311	1	floor_temp	44.2	2026-06-20 21:55:07.225
3312	1	floor_temp	45.3	2026-06-20 22:10:07.225
3313	1	floor_temp	46.4	2026-06-20 22:25:07.225
3314	1	floor_temp	46.5	2026-06-20 22:40:07.225
3315	1	floor_temp	45.7	2026-06-20 22:55:07.225
3316	1	floor_temp	47.2	2026-06-20 23:10:07.225
3317	1	floor_temp	47.2	2026-06-20 23:25:07.225
3318	1	floor_temp	47.1	2026-06-20 23:40:07.225
3319	1	floor_temp	46.1	2026-06-20 23:55:07.225
3320	1	floor_temp	48.9	2026-06-21 00:10:07.225
3321	1	floor_temp	47.8	2026-06-21 00:25:07.225
3322	1	floor_temp	48.9	2026-06-21 00:40:07.225
3323	1	floor_temp	48.4	2026-06-21 00:55:07.225
3324	1	floor_temp	49.9	2026-06-21 01:10:07.225
3325	1	floor_temp	48.9	2026-06-21 01:25:07.225
3326	1	floor_temp	50.3	2026-06-21 01:40:07.225
3327	1	floor_temp	50.0	2026-06-21 01:55:07.225
3328	1	floor_temp	51.4	2026-06-21 02:10:07.225
3329	1	floor_temp	51.4	2026-06-21 02:25:07.225
3330	1	floor_temp	51.4	2026-06-21 02:40:07.225
3331	1	floor_temp	49.7	2026-06-21 02:55:07.225
3332	1	floor_temp	50.7	2026-06-21 03:10:07.225
3333	1	floor_temp	50.7	2026-06-21 03:25:07.225
3334	1	floor_temp	52.3	2026-06-21 03:40:07.225
3335	1	floor_temp	51.0	2026-06-21 03:55:07.225
3336	1	floor_temp	51.9	2026-06-21 04:10:07.225
3337	1	floor_temp	53.3	2026-06-21 04:25:07.225
3338	1	floor_temp	51.4	2026-06-21 04:40:07.225
3339	1	floor_temp	51.4	2026-06-21 04:55:07.225
3340	1	floor_temp	52.5	2026-06-21 05:10:07.225
3341	1	floor_temp	53.2	2026-06-21 05:25:07.225
3342	1	floor_temp	53.0	2026-06-21 05:40:07.225
3343	1	floor_temp	51.9	2026-06-21 05:55:07.225
3344	1	floor_temp	54.0	2026-06-21 06:10:07.225
3345	1	floor_temp	53.8	2026-06-21 06:25:07.225
3346	1	floor_temp	53.2	2026-06-21 06:40:07.225
3347	1	floor_temp	52.9	2026-06-21 06:55:07.225
3348	1	floor_temp	52.4	2026-06-21 07:10:07.225
3349	1	floor_temp	53.3	2026-06-21 07:25:07.225
3350	1	floor_temp	53.3	2026-06-21 07:40:07.225
3351	1	floor_temp	53.5	2026-06-21 07:55:07.225
3352	1	floor_temp	51.4	2026-06-21 08:10:07.225
3353	1	floor_temp	52.9	2026-06-21 08:25:07.225
3354	1	floor_temp	53.2	2026-06-21 08:40:07.225
3355	1	floor_temp	53.3	2026-06-21 08:55:07.225
3356	1	floor_temp	50.9	2026-06-21 09:10:07.225
3357	1	floor_temp	51.4	2026-06-21 09:25:07.225
3358	1	floor_temp	51.8	2026-06-21 09:40:07.225
3359	1	floor_temp	51.8	2026-06-21 09:55:07.225
3360	1	floor_temp	51.1	2026-06-21 10:10:07.225
3361	1	floor_temp	50.9	2026-06-21 10:25:07.225
3362	1	floor_temp	50.1	2026-06-21 10:40:07.225
3363	1	floor_temp	49.5	2026-06-21 10:55:07.225
3364	1	floor_temp	49.2	2026-06-21 11:10:07.225
3365	1	floor_temp	49.9	2026-06-21 11:25:07.225
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password_hash, telegram_id, role_id, created_at, updated_at) FROM stdin;
34	qqq	$2a$10$hF1u9g2X8Jlpbvt0MtyOPujXafI0d5PPYYRR0K38JNXMVMO1XzdEe	\N	3	2026-06-21 11:48:59.998	2026-06-21 11:48:59.998
1	admin	$2a$10$AhbOV2RbgdLpVu2OCXknXeE/CcE8oQBDF5mEHSztvTcdSQWJFwPSC	8254540502	1	2026-06-21 08:50:08.109	2026-06-21 08:50:08.109
35	www	$2a$10$csZtl5vg3KQ4Ugkkjka4xu3s1A6C9IDcwtwfjRtpIs5jKbC2/1p02	\N	2	2026-06-23 09:57:03.284	2026-06-23 09:57:03.284
\.


--
-- Name: commands_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.commands_id_seq', 1, false);


--
-- Name: device_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_cache_id_seq', 2, true);


--
-- Name: device_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_events_id_seq', 2, true);


--
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.devices_id_seq', 33, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.events_id_seq', 50, true);


--
-- Name: parameters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parameters_id_seq', 53, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 33, true);


--
-- Name: telemetry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telemetry_id_seq', 3365, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 35, true);


--
-- Name: commands commands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);


--
-- Name: device_cache device_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_cache
    ADD CONSTRAINT device_cache_pkey PRIMARY KEY (id);


--
-- Name: device_events device_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_events
    ADD CONSTRAINT device_events_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: parameters parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parameters
    ADD CONSTRAINT parameters_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: telemetry telemetry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telemetry
    ADD CONSTRAINT telemetry_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: commands_device_id_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX commands_device_id_status_idx ON public.commands USING btree (device_id, status);


--
-- Name: device_cache_device_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX device_cache_device_id_key ON public.device_cache USING btree (device_id);


--
-- Name: device_event_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX device_event_unique ON public.device_events USING btree (device_id, event_id);


--
-- Name: devices_serial_number_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX devices_serial_number_key ON public.devices USING btree (serial_number);


--
-- Name: events_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_created_at_idx ON public.events USING btree (created_at);


--
-- Name: parameters_key_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX parameters_key_key ON public.parameters USING btree (key);


--
-- Name: roles_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX roles_name_key ON public.roles USING btree (name);


--
-- Name: telemetry_device_id_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX telemetry_device_id_timestamp_idx ON public.telemetry USING btree (device_id, "timestamp");


--
-- Name: users_telegram_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_telegram_id_key ON public.users USING btree (telegram_id);


--
-- Name: users_username_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);


--
-- Name: commands commands_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: events events_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: telemetry telemetry_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telemetry
    ADD CONSTRAINT telemetry_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict HcEQ1OpXYshosiczyFvhDuTZYMd4ADbfpB7cNAn1VMd18AgcgE6OwEnRcfuxiew

