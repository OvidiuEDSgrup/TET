CREATE TABLE [dbo].[Directoare] (
    [HostID]           CHAR (20)   NOT NULL,
    [Director]         CHAR (255)  NOT NULL,
    [Director_parinte] CHAR (255)  NULL,
    [Nivel]            SMALLINT    NOT NULL,
    [Cale]             CHAR (1000) NOT NULL,
    [Nr]               INT         IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[Directoare]([Director] ASC, [Director_parinte] ASC);


GO
CREATE NONCLUSTERED INDEX [Cautare]
    ON [dbo].[Directoare]([HostID] ASC);

