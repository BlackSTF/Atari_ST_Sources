/*********************************************************/
/*  Affichage d'un cha�ne par la fonction GEMDOS Cconws  */
/*    Megamax Laser C         STROUT.C      */
/*********************************************************/

#include <osbind.h>

char  string[255];

main()
{
  strcpy (string, "\33pL'AFFICHAGE INVERS� \33q ");   /* ESC p = Invers� */
  strcat (string, "n'est pas un probl�me sous GEMDOS!");  /* ESC q = Normal */

  Cconws (string);          /* Affichage du texte pr�par� */
  Cconin ();                /* Attend la frappe d'une touche */
}


