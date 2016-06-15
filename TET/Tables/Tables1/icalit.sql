CREATE TABLE [dbo].[icalit] (
    [Cod]               CHAR (20)  NOT NULL,
    [Data]              DATETIME   NOT NULL,
    [Mh]                FLOAT (53) NOT NULL,
    [Umid]              FLOAT (53) NOT NULL,
    [Cs]                FLOAT (53) NOT NULL,
    [Csv]               FLOAT (53) NOT NULL,
    [Ind1]              FLOAT (53) NOT NULL,
    [Ind2]              FLOAT (53) NOT NULL,
    [Ind3]              FLOAT (53) NOT NULL,
    [Toler_mh]          FLOAT (53) NOT NULL,
    [Toler_umid]        FLOAT (53) NOT NULL,
    [Toler_cs]          FLOAT (53) NOT NULL,
    [Toler_csv]         FLOAT (53) NOT NULL,
    [Toler_ind1]        FLOAT (53) NOT NULL,
    [Toler_ind2]        FLOAT (53) NOT NULL,
    [Toler_ind3]        FLOAT (53) NOT NULL,
    [Formula_calc_scaz] FLOAT (53) NOT NULL,
    [Rez1]              CHAR (13)  NOT NULL,
    [Rez2]              CHAR (13)  NOT NULL,
    [Rez3]              CHAR (13)  NOT NULL,
    [Rez4]              FLOAT (53) NOT NULL,
    [Data_rez]          DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Icalit1]
    ON [dbo].[icalit]([Cod] ASC, [Data] ASC);

