CREATE TABLE [dbo].[mesajeASiS] (
    [ID]             INT        IDENTITY (1, 1) NOT NULL,
    [Tip_expeditor]  CHAR (1)   NOT NULL,
    [Expeditor]      CHAR (20)  NOT NULL,
    [Tip_destinatar] CHAR (1)   NOT NULL,
    [Destinatar]     CHAR (20)  NOT NULL,
    [Subiect]        CHAR (30)  NOT NULL,
    [Mesaj]          CHAR (500) NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Ora]            CHAR (6)   NOT NULL,
    [Stare]          CHAR (1)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[mesajeASiS]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [Expeditor]
    ON [dbo].[mesajeASiS]([Tip_expeditor] ASC, [Expeditor] ASC);


GO
CREATE NONCLUSTERED INDEX [Destinatar]
    ON [dbo].[mesajeASiS]([Tip_destinatar] ASC, [Destinatar] ASC);

