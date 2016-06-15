CREATE TABLE [dbo].[CalStd] (
    [Data]       DATETIME  NOT NULL,
    [Data_lunii] DATETIME  NOT NULL,
    [An]         SMALLINT  NOT NULL,
    [Luna]       SMALLINT  NOT NULL,
    [LunaAlfa]   CHAR (15) NOT NULL,
    [Zi]         SMALLINT  NOT NULL,
    [Saptamana]  SMALLINT  NOT NULL,
    [Trimestru]  SMALLINT  NOT NULL,
    [Zi_alfa]    CHAR (10) NOT NULL,
    [Camp1]      CHAR (10) NOT NULL,
    [Camp2]      CHAR (10) NOT NULL,
    [Camp3]      CHAR (10) NOT NULL,
    [Fel_zi]     CHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data]
    ON [dbo].[CalStd]([Data] ASC);

