CREATE TABLE [dbo].[FactSold] (
    [tip]              VARCHAR (1)     NOT NULL,
    [tert]             CHAR (13)       NULL,
    [denTert]          CHAR (30)       NULL,
    [factura]          CHAR (20)       NULL,
    [data]             DATETIME        NULL,
    [data_scadentei]   DATETIME        NULL,
    [val_fara_TVA]     FLOAT (53)      NULL,
    [TVA]              FLOAT (53)      NULL,
    [achitat]          FLOAT (53)      NULL,
    [sold]             DECIMAL (38, 2) NULL,
    [cont]             CHAR (20)       NULL,
    [achitat_interval] FLOAT (53)      NULL
);

