CREATE TABLE [dbo].[mandatar] (
    [Mandatar]  CHAR (6) NOT NULL,
    [Loc_munca] CHAR (9) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[mandatar]([Loc_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [Mandatar]
    ON [dbo].[mandatar]([Mandatar] ASC);

