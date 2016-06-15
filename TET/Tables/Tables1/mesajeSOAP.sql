CREATE TABLE [dbo].[mesajeSOAP] (
    [Identificator]  INT        NOT NULL,
    [Tip_document]   CHAR (10)  NOT NULL,
    [Numar_document] CHAR (30)  NOT NULL,
    [Expeditor]      CHAR (20)  NOT NULL,
    [Nume_expeditor] CHAR (200) NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Stare]          CHAR (1)   NOT NULL,
    [Document]       XML        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[mesajeSOAP]([Identificator] ASC);


GO
CREATE NONCLUSTERED INDEX [Expeditor]
    ON [dbo].[mesajeSOAP]([Expeditor] ASC);

