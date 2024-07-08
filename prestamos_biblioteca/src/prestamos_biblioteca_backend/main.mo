import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

actor LibrarySystem {
    // Definición de un usuario
    type User = {
        id: Nat;
        name: Text;
    };

    // Definición de un libro
    type Book = {
        id: Nat;
        title: Text;
        author: Text;
        available: Bool;
        quantity: Int;  // Nuevo campo para la cantidad de libros disponibles
    };

    // Estado del actor
    var users: [User] = [];
    var books: [Book] = [];
    var nextUserId: Nat = 1;
    var nextBookId: Nat = 1;

    // Función interna: Obtener usuario por ID
    public func getUserById(userId: Nat): async ?User {
        Array.find<User>(users, func(user) { user.id == userId });
    };

    // Función interna: Obtener libro por ID
    public func getBookById(bookId: Nat): async ?Book {
        Array.find<Book>(books, func(book) { book.id == bookId })
    };

    // Función: Agregar un usuario
    public func addUser(name: Text): async User {
        let newUser = {
            id = nextUserId;
            name = name;
        };
        users := Array.append(users, [newUser]);
        nextUserId += 1;
        return newUser;
    };

    // Función: Eliminar un usuario
    public func removeUser(userId: Nat): async Bool {
        users := Array.filter<User>(users, func(user) { user.id != userId });
        if (userId == nextUserId - 1) {
            nextUserId -= 1;
        };
        true;
    };

    // Función: Agregar un libro
    public func addBook(title: Text, author: Text, quantity: Nat): async Book {
        let newBook = {
            id = nextBookId;
            title = title;
            author = author;
            available = true;  // Por defecto está disponible
            quantity = quantity;  // Asignamos la cantidad especificada
        };
        books := Array.append(books, [newBook]);
        nextBookId += 1;
        return newBook;
    };

    // Disponibilidad
    public func isBookAvailable(bookId: Nat): async Bool {
        let book = await getBookById(bookId);
        if (book == null) {
            return false;
        };
        return true;
    };

    // Función: Préstamo de libro
    public func borrowBook(bookId: Nat, userId: Nat): async Bool {
        let bookOpt = await getBookById(bookId);
        let userOpt = await getUserById(userId);
        switch (bookOpt, userOpt) {
            case (?book, ?user) {
                if (book.quantity > 0) {
                    let newBook = {
                        id = book.id;
                        title = book.title;
                        author = book.author;
                        available = book.quantity > 1;  // Actualizar disponibilidad
                        quantity = book.quantity - 1;
                    };
                    books := Array.map<Book, Book>(books, func(b) {
                        if (b.id == bookId) {
                            newBook
                        } else {
                            b
                        }
                    });
                    Debug.print("Libro retirado por el usuario " # user.name # ". Cantidad actual: " # Int.toText(newBook.quantity));
                    return true;
                } else {
                    return false;
                };
            };
            case _ {
                return false;
            };
        }
    };

    // Función: Devolución de libro
    public func returnBook(bookId: Nat, userId: Nat): async Bool {
        let bookOpt = await getBookById(bookId);
        let userOpt = await getUserById(userId);
        switch (bookOpt, userOpt) {
            case (?book, ?user) {
                let newBook = {
                    id = book.id;
                    title = book.title;
                    author = book.author;
                    available = true;  // Actualizar disponibilidad
                    quantity = book.quantity + 1;
                };
                books := Array.map<Book, Book>(books, func(b) {
                    if (b.id == bookId) {
                        newBook
                    } else {
                        b
                    }
                });
                Debug.print("Libro devuelto por el usuario " # user.name # ". Cantidad actual: " # Int.toText(newBook.quantity));
                return true;
            };
            case _ {
                return false;
            };
        }
    };
}
