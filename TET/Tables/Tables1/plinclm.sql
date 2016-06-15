CREATE TABLE [dbo].[plinclm] (
    [Loc_de_munca]  CHAR (9)   NOT NULL,
    [Total_incasat] FLOAT (53) NOT NULL,
    [Total_platit]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[plinclm]([Loc_de_munca] ASC);

