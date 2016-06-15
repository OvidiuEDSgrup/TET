CREATE TABLE [dbo].[gruputiliz] (
    [ID_utilizator] CHAR (10) NOT NULL,
    [ID_grup]       CHAR (10) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[gruputiliz]([ID_utilizator] ASC, [ID_grup] ASC);

