CREATE TABLE [dbo].[lansari] (
    [Subunitate]      CHAR (9)   NOT NULL,
    [Lansare]         CHAR (13)  NOT NULL,
    [Descriere]       CHAR (30)  NOT NULL,
    [Stare]           CHAR (1)   NOT NULL,
    [Data_lunii]      DATETIME   NOT NULL,
    [Data_lansarii]   DATETIME   NOT NULL,
    [Data_inchiderii] DATETIME   NOT NULL,
    [Cod]             CHAR (20)  NOT NULL,
    [Cantitate]       FLOAT (53) NOT NULL,
    [Loc_munca]       CHAR (9)   NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Data_operarii]   DATETIME   NOT NULL,
    [Ora_operarii]    CHAR (6)   NOT NULL,
    [UM]              CHAR (1)   NOT NULL,
    [Alfa1]           CHAR (13)  NOT NULL,
    [Alfa2]           CHAR (13)  NOT NULL,
    [Alfa3]           CHAR (13)  NOT NULL,
    [Val1]            FLOAT (53) NOT NULL,
    [Val2]            FLOAT (53) NOT NULL,
    [Val3]            FLOAT (53) NOT NULL,
    [Data]            DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Lans1]
    ON [dbo].[lansari]([Subunitate] ASC, [Lansare] ASC, [Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Lans2]
    ON [dbo].[lansari]([Subunitate] ASC, [Data_lunii] ASC, [Lansare] ASC, [Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Lans3]
    ON [dbo].[lansari]([Subunitate] ASC, [Data_lansarii] ASC, [Cod] ASC, [Data_lunii] ASC, [Lansare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Lans4]
    ON [dbo].[lansari]([Subunitate] ASC, [Loc_munca] ASC, [Cod] ASC, [Data_lansarii] ASC, [Data_lunii] ASC, [Lansare] ASC);


GO
CREATE NONCLUSTERED INDEX [Lans5]
    ON [dbo].[lansari]([Descriere] ASC);

