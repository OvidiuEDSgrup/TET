CREATE TABLE [dbo].[combins] (
    [Hostid]          CHAR (20)  NOT NULL,
    [Gestiune]        CHAR (9)   NOT NULL,
    [Cod]             CHAR (20)  NOT NULL,
    [Culoare]         CHAR (20)  NOT NULL,
    [Cantitate_1]     FLOAT (53) NOT NULL,
    [Cantitate_2]     FLOAT (53) NOT NULL,
    [Cantitate_3]     FLOAT (53) NOT NULL,
    [Cantitate_4]     FLOAT (53) NOT NULL,
    [Cantitate_5]     FLOAT (53) NOT NULL,
    [Cantitate_6]     FLOAT (53) NOT NULL,
    [Cantitate_7]     FLOAT (53) NOT NULL,
    [Cantitate_8]     FLOAT (53) NOT NULL,
    [Cantitate_9]     FLOAT (53) NOT NULL,
    [Cantitate_10]    FLOAT (53) NOT NULL,
    [Cantitate_11]    FLOAT (53) NOT NULL,
    [Cantitate_12]    FLOAT (53) NOT NULL,
    [Cantitate_13]    FLOAT (53) NOT NULL,
    [Cantitate_14]    FLOAT (53) NOT NULL,
    [Cantitate_15]    FLOAT (53) NOT NULL,
    [Cantitate_16]    FLOAT (53) NOT NULL,
    [Cantitate_17]    FLOAT (53) NOT NULL,
    [Cantitate_18]    FLOAT (53) NOT NULL,
    [Cantitate_19]    FLOAT (53) NOT NULL,
    [Cantitate_20]    FLOAT (53) NOT NULL,
    [Cantitate_21]    FLOAT (53) NOT NULL,
    [Cantitate_22]    FLOAT (53) NOT NULL,
    [Cantitate_23]    FLOAT (53) NOT NULL,
    [Cantitate_24]    FLOAT (53) NOT NULL,
    [Cantitate_25]    FLOAT (53) NOT NULL,
    [Cantitate_26]    FLOAT (53) NOT NULL,
    [Cantitate_27]    FLOAT (53) NOT NULL,
    [Cantitate_28]    FLOAT (53) NOT NULL,
    [Cantitate_29]    FLOAT (53) NOT NULL,
    [Cantitate_30]    FLOAT (53) NOT NULL,
    [Cantitate_total] FLOAT (53) NOT NULL,
    [Cod_intrare]     CHAR (13)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CombiSerii]
    ON [dbo].[combins]([Hostid] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Culoare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Culoare]
    ON [dbo].[combins]([Hostid] ASC, [Gestiune] ASC, [Cod] ASC, [Culoare] ASC, [Cod_intrare] ASC);

