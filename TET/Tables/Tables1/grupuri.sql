CREATE TABLE [dbo].[grupuri] (
    [ID]   CHAR (10) NOT NULL,
    [Nume] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Grutiliz]
    ON [dbo].[grupuri]([ID] ASC);

