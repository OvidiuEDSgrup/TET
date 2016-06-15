CREATE TABLE [dbo].[chestionar] (
    [Chestionar]   CHAR (13)  NOT NULL,
    [Nr_Intrebare] SMALLINT   NOT NULL,
    [Intrebare]    CHAR (100) NOT NULL,
    [Tip_raspuns]  CHAR (1)   NOT NULL,
    [Varianta1]    CHAR (15)  NOT NULL,
    [Varianta2]    CHAR (15)  NOT NULL,
    [Varianta3]    CHAR (15)  NOT NULL,
    [Varianta4]    CHAR (15)  NOT NULL,
    [Varianta5]    CHAR (15)  NOT NULL,
    [Varianta6]    CHAR (15)  NOT NULL,
    [Varianta7]    CHAR (15)  NOT NULL,
    [Varianta8]    CHAR (15)  NOT NULL,
    [Varianta9]    CHAR (15)  NOT NULL,
    [Varianta10]   CHAR (15)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[chestionar]([Chestionar] ASC, [Nr_Intrebare] ASC);

