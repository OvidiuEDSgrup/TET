CREATE TABLE [dbo].[tet_oportunitati] (
    [Tert]       VARCHAR (20) NULL,
    [Data_lunii] DATETIME     NULL,
    [Nr_opp]     SMALLINT     NULL,
    [Val_opp]    REAL         NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tet_oportunitati]([Tert] ASC, [Data_lunii] ASC);

