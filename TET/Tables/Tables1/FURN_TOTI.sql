CREATE TABLE [dbo].[FURN_TOTI] (
    [NRCRT]                   BIGINT        NULL,
    [VENDOR_NAME]             VARCHAR (58)  NULL,
    [VENDOR_SITE_CODE]        VARCHAR (20)  NULL,
    [VENDOR_TYPE_LOOKUP_CODE] VARCHAR (6)   NULL,
    [NUM_1099]                VARCHAR (16)  NULL,
    [ATTRIBUTE14]             VARCHAR (50)  NULL,
    [ATTRIBUTE15]             VARCHAR (16)  NULL,
    [VAT_REGISTRATION_NUM]    VARCHAR (20)  NULL,
    [ADDRESS_LINE1]           VARCHAR (66)  NULL,
    [ADDRESS_LINES_ALT]       VARCHAR (MAX) NULL,
    [ADDRESS_LINE2]           VARCHAR (69)  NULL,
    [ADDRESS_LINE3]           VARCHAR (23)  NULL,
    [STATE]                   VARCHAR (25)  NULL,
    [ZIP]                     VARCHAR (50)  NULL,
    [PROVINCE]                VARCHAR (7)   NULL,
    [COUNTRY]                 VARCHAR (2)   NULL,
    [AREA_CODE]               VARCHAR (MAX) NULL,
    [PHONE]                   VARCHAR (MAX) NULL,
    [VAT_REGISTRATION_NUM1]   VARCHAR (20)  NULL
);

