﻿CREATE TABLE [dbo].[TEMP_5025125] (
    [FLD1] CHAR (13)  NOT NULL,
    [FLD2] CHAR (80)  NOT NULL,
    [FLD3] CHAR (2)   NOT NULL,
    [FLD4] CHAR (10)  NOT NULL,
    [FLD5] DATETIME   NOT NULL,
    [FLD6] CHAR (20)  NOT NULL,
    [FLD7] CHAR (20)  NOT NULL,
    [FLD8] CHAR (20)  NOT NULL,
    [TS]   ROWVERSION NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KEY_TSTEMP_5025125]
    ON [dbo].[TEMP_5025125]([TS] ASC);

