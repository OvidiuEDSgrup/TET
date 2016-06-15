﻿CREATE TABLE [dbo].[TEMP_4286490] (
    [FLD1] CHAR (13)  NOT NULL,
    [FLD2] CHAR (20)  NOT NULL,
    [FLD3] DATETIME   NOT NULL,
    [TS]   ROWVERSION NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [KEY_TSTEMP_4286490]
    ON [dbo].[TEMP_4286490]([TS] ASC);
