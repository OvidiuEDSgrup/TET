CREATE TABLE [dbo].[80_FURN-Furnizori Oracle 21 nov 2011_DC] (
    [   NRCRT]                SMALLINT     NULL,
    [VENDOR_ID]               INT          NULL,
    [VENDOR_NAME]             VARCHAR (58) NULL,
    [EMPLOYEE_ID]             SMALLINT     NULL,
    [VENDOR_TYPE_LOOKUP_CODE] VARCHAR (8)  NULL,
    [NUM_1099]                VARCHAR (13) NULL,
    [ATTRIBUTE14]             BIGINT       NULL,
    [ATTRIBUTE15]             VARCHAR (16) NULL,
    [VAT_REGISTRATION_NUM]    VARCHAR (20) NULL,
    [ID]                      INT          IDENTITY (1, 1) NOT NULL
);

