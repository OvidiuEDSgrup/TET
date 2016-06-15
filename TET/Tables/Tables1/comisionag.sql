CREATE TABLE [dbo].[comisionag] (
    [tip_comision] CHAR (2)   NOT NULL,
    [dep_zile]     CHAR (6)   NOT NULL,
    [N1]           FLOAT (53) NOT NULL,
    [N2]           FLOAT (53) NOT NULL,
    [N3]           FLOAT (53) NOT NULL,
    [N4]           FLOAT (53) NOT NULL,
    [N5]           FLOAT (53) NOT NULL,
    [N6]           FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [tip_dep]
    ON [dbo].[comisionag]([tip_comision] ASC, [dep_zile] ASC);

