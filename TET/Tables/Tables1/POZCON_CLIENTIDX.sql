﻿CREATE TABLE [dbo].[POZCON_CLIENTIDX] (
    [Subunitate]           CHAR (9)   NOT NULL,
    [Tip]                  CHAR (2)   NOT NULL,
    [Contract]             CHAR (20)  NOT NULL,
    [Tert]                 CHAR (13)  NOT NULL,
    [Punct_livrare]        CHAR (13)  NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Cod]                  CHAR (30)  NOT NULL,
    [Cantitate]            FLOAT (53) NOT NULL,
    [Pret]                 FLOAT (53) NOT NULL,
    [Pret_promotional]     FLOAT (53) NOT NULL,
    [Discount]             REAL       NOT NULL,
    [Termen]               DATETIME   NOT NULL,
    [Factura]              CHAR (9)   NOT NULL,
    [Cant_disponibila]     FLOAT (53) NOT NULL,
    [Cant_aprobata]        FLOAT (53) NOT NULL,
    [Cant_realizata]       FLOAT (53) NOT NULL,
    [Valuta]               CHAR (3)   NOT NULL,
    [Cota_TVA]             REAL       NOT NULL,
    [Suma_TVA]             FLOAT (53) NOT NULL,
    [Mod_de_plata]         CHAR (8)   NOT NULL,
    [UM]                   CHAR (1)   NOT NULL,
    [Zi_scadenta_din_luna] SMALLINT   NOT NULL,
    [Explicatii]           CHAR (200) NOT NULL,
    [Numar_pozitie]        INT        NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Data_operarii]        DATETIME   NOT NULL,
    [Ora_operarii]         CHAR (6)   NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX1]
    ON [dbo].[POZCON_CLIENTIDX]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Cod] ASC, [Data] ASC);

