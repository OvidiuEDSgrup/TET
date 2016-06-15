CREATE TABLE [dbo].[extconmed] (
    [Data]                        DATETIME   NOT NULL,
    [Marca]                       CHAR (6)   NOT NULL,
    [Data_inceput]                DATETIME   NOT NULL,
    [Serie_certificat_CM]         CHAR (10)  NOT NULL,
    [Nr_certificat_CM]            CHAR (10)  NOT NULL,
    [Serie_certificat_CM_initial] CHAR (10)  NOT NULL,
    [Nr_certificat_CM_initial]    CHAR (10)  NOT NULL,
    [Indemnizatie_FAMBP]          FLOAT (53) NOT NULL,
    [Zile_CAS]                    SMALLINT   NOT NULL,
    [Zile_FAMBP]                  SMALLINT   NOT NULL,
    [Alfa]                        CHAR (10)  NOT NULL,
    [Data_rez]                    DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[extconmed]([Data] ASC, [Marca] ASC, [Data_inceput] ASC);

